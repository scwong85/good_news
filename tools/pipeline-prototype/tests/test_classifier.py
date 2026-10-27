"""Tests for the reference classifier. Pure Python: no database, no network."""

import json
from copy import deepcopy
from datetime import UTC, datetime, timedelta

import pytest

from classifier import Item, classify, load_rules
from classifier.data import load_labels, load_sources, to_item
from classifier.engine import DEFAULT_RULES_PATH, RulesError, validate_rules
from classifier.evaluate import run
from classifier.export_golden import build

NOW = datetime(2026, 10, 27, 12, 0, tzinfo=UTC)
BASELINE = json.loads((DEFAULT_RULES_PATH.parent / "baseline_metrics.json").read_text())


@pytest.fixture(scope="module")
def rules():
    return load_rules()


def item(title, excerpt="", **kw):
    defaults = dict(
        source="Positive News",
        url="https://example.com/a",
        published_at=NOW - timedelta(days=1),
        source_trust=0.95,
    )
    defaults.update(kw)
    return Item(title=title, excerpt=excerpt, **defaults)


# --- rules file ---------------------------------------------------------------


def test_rules_file_is_valid(rules):
    validate_rules(rules)
    ids = [r["id"] for r in rules["score_rules"]]
    assert len(ids) == len(set(ids))
    assert rules["thresholds"]["explore"] < rules["thresholds"]["today"]


@pytest.mark.parametrize(
    "mutate", [lambda r: r.pop("thresholds"), lambda r: r["score_rules"][0].update(field="nope")]
)
def test_invalid_rules_are_rejected(rules, mutate):
    bad = deepcopy(rules)
    mutate(bad)
    with pytest.raises(RulesError):
        validate_rules(bad)


def test_bad_regex_is_rejected(rules):
    bad = deepcopy(rules)
    bad["score_rules"][0]["regex"] = "("
    with pytest.raises(Exception):  # noqa: B017  (re.error)
        validate_rules(bad)


# --- stage 1 ------------------------------------------------------------------


@pytest.mark.parametrize(
    "kw,reason",
    [
        (dict(url="ftp://example.com/a"), "invalid_url"),
        (dict(url=""), "invalid_url"),
        (dict(published_at=None), "missing_date"),
        (dict(published_at=NOW - timedelta(days=30)), "too_old"),
        (dict(url="https://example.com/sponsored/x"), "stage1:sponsored_url"),
        (dict(language="fr"), "unsupported_language"),
    ],
)
def test_stage1_exclusions(rules, kw, reason):
    out = classify(item("Wetlands restored by volunteers", **kw), rules, NOW)
    assert (out.route, out.reason, out.score) == ("excluded", reason, 0.0)


def test_empty_title_and_roundups_excluded(rules):
    assert classify(item("   "), rules, NOW).reason == "missing_title"
    assert (
        classify(item("Good News This Week: October 24"), rules, NOW).reason
        == "stage1:roundup_good_news"
    )
    assert classify(item("What We’re Reading: trees"), rules, NOW).reason == "stage1:reading_list"


def test_age_filter_only_applies_with_now(rules):
    old = item("Wetlands restored by volunteers", published_at=NOW - timedelta(days=400))
    assert classify(old, rules, None).route != "excluded"
    assert classify(old, rules, NOW).reason == "too_old"


def test_source_specific_exclude(rules):
    yes = item("Inspiration: Someone", source="YES! Magazine", source_trust=0.6)
    other = item("Inspiration: Someone", source="Positive News")
    assert classify(yes, rules, NOW).reason == "stage1:yes_inspiration_column"
    assert classify(other, rules, NOW).reason != "stage1:yes_inspiration_column"


# --- scoring and routing --------------------------------------------------------


def test_strong_constructive_story_routes_to_today(rules):
    out = classify(item("Wetlands restored by volunteers, study finds 40% more birds"), rules, NOW)
    assert out.route == "today" and out.score >= rules["thresholds"]["today"]
    assert {"data_cited", "study_referenced"} <= set(out.evidence_signals)
    assert "environment" in out.topics


def test_negative_news_is_excluded(rules):
    out = classify(item("Attack kills dozens as war crisis deepens", source_trust=0.5), rules, NOW)
    assert out.route == "excluded" and out.reason == "low_score"


def test_listicle_and_how_to_are_penalised(rules):
    base = classify(item("Wetlands restored by volunteers"), rules, NOW).score
    assert classify(item("5 ways wetlands restored by volunteers"), rules, NOW).score < base
    assert classify(item("How to help wetlands restored by volunteers"), rules, NOW).score < base


def test_today_needs_evidence_unless_source_is_highly_trusted(rules):
    text = "Volunteers launched a partnership to restore and protect a river"
    trusted = classify(item(text, source_trust=0.95), rules, NOW)
    untrusted = classify(item(text, source_trust=0.7), rules, NOW)
    assert trusted.route == "today" and not trusted.evidence_signals
    assert untrusted.route == "explore" and untrusted.reason == "no_evidence"


def test_today_needs_constructive_vocabulary(rules):
    out = classify(
        item("New study of 12,000 people at the University of Oxford", source_trust=0.7), rules, NOW
    )
    assert out.route != "today"


def test_veto_keeps_story_out_of_today(rules):
    out = classify(
        item(
            "Volunteers restored a river despite the war, study finds 40% recovery",
            source_trust=0.95,
        ),
        rules,
        NOW,
    )
    assert out.route != "today"


def test_score_is_clamped_and_rounded(rules):
    out = classify(
        item("war attack killed genocide scandal fraud lawsuit", source_trust=0.1), rules, NOW
    )
    assert 0.0 <= out.score <= 1.0 and out.score == round(out.score, 6)


def test_every_decision_has_an_explanation(rules):
    out = classify(item("Wetlands restored by volunteers"), rules, NOW)
    assert out.explanation and all(
        {"rule", "group", "weight", "match"} <= set(e) for e in out.explanation
    )
    assert out.rules_version == rules["rules_version"]
    assert classify(item("   "), rules, NOW).reason  # excluded items explain why too


def test_classification_is_deterministic(rules):
    a = classify(item("Wetlands restored by volunteers, study finds 40% more birds"), rules, NOW)
    b = classify(item("Wetlands restored by volunteers, study finds 40% more birds"), rules, NOW)
    assert a.as_dict() == b.as_dict()


def test_story_type_default_and_cap(rules):
    out = classify(
        item("A quiet profile of a kind person", "Resilient and inspiring.", source_trust=0.95),
        rules,
        NOW,
    )
    if out.route != "excluded":
        assert 1 <= len(out.story_types) <= rules["max_story_types"]


# --- golden cases + evaluation --------------------------------------------------


def test_golden_file_is_up_to_date(rules):
    golden = DEFAULT_RULES_PATH.parent / "golden_cases.jsonl"
    expected = "".join(json.dumps(c, ensure_ascii=False, sort_keys=True) + "\n" for c in build())
    assert golden.read_text(encoding="utf-8") == expected, "run: python -m classifier.export_golden"


def test_labeled_data_is_consistent():
    sources = load_sources()
    rows = load_labels("all")
    assert len({r["url"] for r in rows}) == len(rows) >= 290
    assert {r["split"] for r in rows} == {"dev", "dev2", "test2"}
    for r in rows:
        assert r["source"] in sources
        assert (r["label"] == "constructive") == (r["rejection_reason"] is None)
        to_item(r, sources)  # parses


@pytest.mark.parametrize("split", ["tune", "test2"])
def test_metrics_do_not_regress(split):
    """Guard against accidental rule changes. After an intentional rules change, re-run the
    evaluation and update rules/baseline_metrics.json together with the rules version."""
    _, report, rules = run(split)
    base = BASELINE[split]
    assert rules["rules_version"] == BASELINE["rules_version"], "update rules/baseline_metrics.json"
    assert report["today"]["precision"] >= base["today_precision"] - 0.02
    assert report["route_accuracy"] >= base["route_accuracy"] - 0.02
    assert report["tier1_route_accuracy"] >= base["tier1_route_accuracy"] - 0.02

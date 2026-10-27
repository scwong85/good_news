"""Deterministic classifier. Keep it simple and portable: regexes, additive weights, no randomness.

Portability rules for rules.json (so the Dart port behaves the same):
- patterns use only features common to Python `re` and Dart `RegExp` (no inline flags, no
  named groups, no possessive quantifiers); flags come from the rule's "flags" ("i" or "").
- matching is `search` (anywhere in the field), the first match is recorded in the explanation.
- weights are summed in rule order; the result is clamped to [0, 1] and rounded to 6 places.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from urllib.parse import urlsplit

DEFAULT_RULES_PATH = Path(__file__).resolve().parents[3] / "rules" / "rules.json"
FIELDS = {"title", "excerpt", "text", "url"}


@dataclass
class Item:
    source: str
    title: str
    excerpt: str
    url: str
    published_at: datetime | None = None
    source_trust: float = 0.5
    source_tier: int = 1
    language: str | None = None  # None = unknown (skip the language check)

    @property
    def text(self) -> str:
        return f"{self.title}. {self.excerpt}" if self.excerpt else self.title


@dataclass
class Classification:
    route: str  # today | explore | excluded
    score: float
    reason: str = ""  # why excluded / why not today
    topics: list[str] = field(default_factory=list)
    story_types: list[str] = field(default_factory=list)
    evidence_signals: list[str] = field(default_factory=list)
    explanation: list[dict] = field(default_factory=list)
    rules_version: str = ""

    def as_dict(self) -> dict:
        return {
            "route": self.route,
            "score": self.score,
            "reason": self.reason,
            "topics": self.topics,
            "story_types": self.story_types,
            "evidence_signals": self.evidence_signals,
            "explanation": self.explanation,
            "rules_version": self.rules_version,
        }


class RulesError(ValueError):
    pass


def _flags(spec: str) -> int:
    return re.IGNORECASE if "i" in spec else 0


def _compile(rule: dict) -> re.Pattern:
    return re.compile(rule["regex"], _flags(rule.get("flags", "i")))


def load_rules(path: str | Path | None = None) -> dict:
    rules = json.loads(Path(path or DEFAULT_RULES_PATH).read_text(encoding="utf-8"))
    validate_rules(rules)
    return rules


def validate_rules(rules: dict) -> None:
    for key in ("rules_version", "base_score", "thresholds", "score_rules", "groups"):
        if key not in rules:
            raise RulesError(f"rules missing '{key}'")
    seen: set[str] = set()
    for rule in rules["score_rules"]:
        for key in ("id", "group", "field", "regex", "weight"):
            if key not in rule:
                raise RulesError(f"score rule missing '{key}': {rule}")
        if rule["id"] in seen:
            raise RulesError(f"duplicate rule id {rule['id']}")
        seen.add(rule["id"])
        if rule["field"] not in FIELDS:
            raise RulesError(f"bad field in {rule['id']}")
        if rule["group"] not in rules["groups"]:
            raise RulesError(f"unknown group in {rule['id']}")
        _compile(rule)  # raises re.error on a bad pattern
    for rule in rules.get("stage1", {}).get("global_excludes", []):
        _compile(rule)


def _field(item: Item, name: str) -> str:
    return getattr(item, name)


def _first_match(rule: dict, item: Item) -> str | None:
    m = _compile(rule).search(_field(item, rule["field"]))
    return m.group(0) if m else None


def _stage1(item: Item, rules: dict, now: datetime | None) -> tuple[str, str] | None:
    s1 = rules.get("stage1", {})
    parts = urlsplit(item.url or "")
    if parts.scheme not in {"http", "https"} or not parts.hostname:
        return ("excluded", "invalid_url")
    if not item.title.strip():
        return ("excluded", "missing_title")
    allowed = rules.get("language_allowlist")
    if allowed and item.language and item.language not in allowed:
        return ("excluded", "unsupported_language")
    if item.published_at is None:
        return ("excluded", "missing_date")
    window = rules.get("age_window_days")
    if now is not None and window and item.published_at < now - timedelta(days=window):
        return ("excluded", "too_old")
    host = parts.hostname.lower()
    for dom in s1.get("blocked_domains", []):
        if host == dom or host.endswith("." + dom):
            return ("excluded", f"blocked_domain:{dom}")
    for rule in s1.get("global_excludes", []) + s1.get("source_excludes", {}).get(item.source, []):
        if _first_match(rule, item) is not None:
            return ("excluded", f"stage1:{rule['id']}")
    return None


def _keyword_matches(table: dict, item: Item) -> dict[str, int]:
    counts: dict[str, int] = {}
    for name, patterns in table.items():
        n = 0
        for pat in patterns:
            if re.search(pat, item.text, re.IGNORECASE):
                n += 1
        if n:
            counts[name] = n
    return counts


def classify(item: Item, rules: dict, now: datetime | None = None) -> Classification:
    version = rules["rules_version"]
    blocked = _stage1(item, rules, now)
    if blocked:
        return Classification(route=blocked[0], score=0.0, reason=blocked[1], rules_version=version)

    explanation: list[dict] = []
    group_totals = {name: 0.0 for name in rules["groups"]}
    signals: list[str] = []
    group_hits = {name: 0 for name in rules["groups"]}
    veto = False
    for rule in rules["score_rules"]:
        hit = _first_match(rule, item)
        if hit is None:
            continue
        group_totals[rule["group"]] += rule["weight"]
        group_hits[rule["group"]] += 1
        explanation.append(
            {
                "rule": rule["id"],
                "group": rule["group"],
                "weight": rule["weight"],
                "match": hit[:60],
            }
        )
        if rule.get("signal") and rule["signal"] not in signals:
            signals.append(rule["signal"])
        veto = veto or bool(rule.get("veto"))

    score = rules["base_score"]
    for name, total in group_totals.items():
        cap = rules["groups"][name].get("cap")
        if cap is not None:
            total = min(total, cap) if cap >= 0 else max(total, cap)
        score += total
    prior = (item.source_trust - rules.get("trust_center", 0.5)) * rules.get(
        "source_prior_scale", 0.2
    )
    if prior:
        explanation.append(
            {
                "rule": "source_prior",
                "group": "source",
                "weight": round(prior, 6),
                "match": item.source,
            }
        )
    score = round(max(0.0, min(1.0, score + prior)), 6)

    th = rules["thresholds"]
    need = rules.get("today_requires", {})
    has_evidence = len(signals) >= need.get("min_evidence_signals", 0)
    trusted = item.source_trust >= need.get("or_source_trust_at_least", 2.0)
    has_vocab = all(group_hits.get(g, 0) >= n for g, n in need.get("min_group_matches", {}).items())
    reason = ""
    if score >= th["today"] and not veto and has_vocab and (has_evidence or trusted):
        route = "today"
    elif score >= th["explore"]:
        route = "explore"
        if score >= th["today"]:
            reason = "veto" if veto else ("no_vocabulary" if not has_vocab else "no_evidence")
    else:
        route, reason = "excluded", "low_score"

    topics = _top_names(_keyword_matches(rules.get("topics", {}), item), rules.get("max_topics", 3))
    types = _top_names(
        _keyword_matches(rules.get("story_types", {}), item), rules.get("max_story_types", 2)
    )
    if route != "excluded" and not types and rules.get("default_story_type"):
        types = [rules["default_story_type"]]
    return Classification(
        route=route,
        score=score,
        reason=reason,
        topics=topics,
        story_types=types,
        evidence_signals=signals,
        explanation=explanation,
        rules_version=version,
    )


def _top_names(counts: dict[str, int], limit: int) -> list[str]:
    # Highest count first; ties keep rules.json order (dict order), so the result is stable.
    order = {name: i for i, name in enumerate(counts)}
    ranked = sorted(counts, key=lambda n: (-counts[n], order[n]))
    return ranked[:limit]

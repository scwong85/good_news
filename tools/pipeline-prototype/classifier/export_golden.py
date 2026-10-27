"""Write rules/golden_cases.jsonl: inputs and expected outputs for the Dart parity test.

    python -m classifier.export_golden            # rewrite the file
    python -m classifier.export_golden --check    # fail if the committed file is stale
Labeled items use now=None (no age filter). Synthetic cases cover Stage-1 filters.
"""

import argparse
import json
import sys
from datetime import UTC, datetime
from pathlib import Path

from .data import load_labels, load_sources, to_item
from .engine import DEFAULT_RULES_PATH, Item, classify, load_rules

GOLDEN = DEFAULT_RULES_PATH.parent / "golden_cases.jsonl"
NOW = datetime(2026, 10, 27, 12, 0, tzinfo=UTC)


def _case(item: Item, rules: dict, now: datetime | None, name: str) -> dict:
    out = classify(item, rules, now)
    return {
        "name": name,
        "now": now.isoformat().replace("+00:00", "Z") if now else None,
        "input": {
            "source": item.source,
            "title": item.title,
            "excerpt": item.excerpt,
            "url": item.url,
            "published_at": item.published_at.isoformat().replace("+00:00", "Z")
            if item.published_at
            else None,
            "source_trust": item.source_trust,
            "language": item.language,
        },
        "expected": {
            "route": out.route,
            "score": out.score,
            "reason": out.reason,
            "topics": out.topics,
            "story_types": out.story_types,
            "evidence_signals": out.evidence_signals,
            "rules": [e["rule"] for e in out.explanation],
        },
    }


def synthetic(rules: dict) -> list[dict]:
    base = dict(source="Positive News", excerpt="", source_trust=0.95)
    fresh = datetime(2026, 10, 26, tzinfo=UTC)
    cases = [
        (
            "old_article",
            Item(
                title="Rivers recovering",
                url="https://e.com/a",
                published_at=datetime(2026, 9, 1, tzinfo=UTC),
                **base,
            ),
            NOW,
        ),
        (
            "missing_date",
            Item(title="Rivers recovering", url="https://e.com/a", published_at=None, **base),
            NOW,
        ),
        (
            "bad_scheme",
            Item(title="Rivers recovering", url="ftp://e.com/a", published_at=fresh, **base),
            NOW,
        ),
        ("empty_title", Item(title="  ", url="https://e.com/a", published_at=fresh, **base), NOW),
        (
            "sponsored_url",
            Item(
                title="Rivers recovering",
                url="https://e.com/sponsored/a",
                published_at=fresh,
                **base,
            ),
            NOW,
        ),
        (
            "roundup_title",
            Item(
                title="What went right this week: rivers",
                url="https://e.com/a",
                published_at=fresh,
                **base,
            ),
            NOW,
        ),
        (
            "language",
            Item(
                title="Rios recuperandose",
                url="https://e.com/a",
                published_at=fresh,
                language="es",
                **base,
            ),
            NOW,
        ),
        (
            "plain_recovery",
            Item(
                title="Wetlands restored by volunteers, study finds 40% more birds",
                url="https://e.com/a",
                published_at=fresh,
                **base,
            ),
            NOW,
        ),
    ]
    return [_case(i, rules, n, name) for name, i, n in cases]


def build() -> list[dict]:
    rules = load_rules()
    sources = load_sources()
    cases = [
        _case(to_item(r, sources), rules, None, f"{r['split']}:{r['url']}")
        for r in load_labels("all")
    ]
    return cases + synthetic(rules)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    text = "".join(json.dumps(c, ensure_ascii=False, sort_keys=True) + "\n" for c in build())
    if args.check:
        if not Path(GOLDEN).exists() or Path(GOLDEN).read_text(encoding="utf-8") != text:
            print("rules/golden_cases.jsonl is stale: run python -m classifier.export_golden")
            return 1
        return 0
    Path(GOLDEN).write_text(text, encoding="utf-8")
    print(f"wrote {GOLDEN} ({text.count(chr(10))} cases)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

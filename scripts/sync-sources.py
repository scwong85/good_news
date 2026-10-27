#!/usr/bin/env python3
"""Generate app/assets/sources.json from docs/source-allowlist.csv (stdlib only).

    python3 scripts/sync-sources.py           # write the asset
    python3 scripts/sync-sources.py --check   # exit 1 if the asset is stale

Only active, feed-verified sources are bundled. Source ids are slugs of the name.
"""

import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "docs" / "source-allowlist.csv"
OUT = ROOT / "app" / "assets" / "sources.json"


def slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def build() -> str:
    sources = []
    with CSV_PATH.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["active"].strip().lower() != "true" or row["feed_verified"].strip().lower() != "true":
                continue
            sources.append(
                {
                    "id": slug(row["name"]),
                    "name": row["name"],
                    "homepage_url": row["homepage_url"],
                    "rss_url": row["rss_url"],
                    "tier": int(row["tier"]),
                    "trust_score": float(row["trust_score"]),
                    "language": row["language"],
                    "regions": [r for r in row["regions"].split(";") if r],
                }
            )
    ids = [s["id"] for s in sources]
    assert len(ids) == len(set(ids)), "duplicate source ids"
    return json.dumps({"generated_from": "docs/source-allowlist.csv", "sources": sources}, indent=1, ensure_ascii=False) + "\n"


def main() -> int:
    text = build()
    if "--check" in sys.argv:
        if not OUT.parent.exists():
            print("app/assets not created yet: skipping sources sync check")
            return 0
        if not OUT.exists() or OUT.read_text(encoding="utf-8") != text:
            print("app/assets/sources.json is stale: run python3 scripts/sync-sources.py")
            return 1
        return 0
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text, encoding="utf-8")
    print(f"wrote {OUT} ({text.count(chr(34) + 'id' + chr(34))} sources)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

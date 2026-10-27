"""Load labeled data and the source list for evaluation."""

import csv
import json
from datetime import datetime
from pathlib import Path

from .engine import Item

REPO_ROOT = Path(__file__).resolve().parents[3]
LABELS = REPO_ROOT / "data" / "seed_labels.jsonl"
SOURCES = REPO_ROOT / "docs" / "source-allowlist.csv"
# dev + dev2 are used for tuning; test2 is the held-out set (run it rarely, never tune on it).
SPLIT_GROUPS = {"tune": {"dev", "dev2"}}


def load_sources(path: Path = SOURCES) -> dict[str, dict]:
    with path.open(newline="", encoding="utf-8") as f:
        return {r["name"]: r for r in csv.DictReader(f)}


def load_labels(split: str = "all", path: Path = LABELS) -> list[dict]:
    rows = [
        json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()
    ]
    if split == "all":
        return rows
    wanted = SPLIT_GROUPS.get(split, {split})
    return [r for r in rows if r.get("split") in wanted]


def to_item(row: dict, sources: dict[str, dict]) -> Item:
    src = sources.get(row["source"], {})
    published = row.get("published_at")
    return Item(
        source=row["source"],
        title=row["title"],
        excerpt=row.get("excerpt", ""),
        url=row["url"],
        published_at=datetime.fromisoformat(published.replace("Z", "+00:00"))
        if published
        else None,
        source_trust=float(src.get("trust_score", 0.5)),
        source_tier=int(src.get("tier", 1)),
    )

"""Evaluate rules on the labeled set.

python -m classifier.evaluate --split tune           # dev + dev2: tune on these
python -m classifier.evaluate --split test2          # held-out: run rarely, never tune on it
python -m classifier.evaluate --split tune --errors  # list mistakes
"""

import argparse
import json

from .data import load_labels, load_sources, to_item
from .engine import DEFAULT_RULES_PATH, classify, load_rules
from .metrics import evaluate


def run(split: str, rules_path: str | None = None):
    rules = load_rules(rules_path)
    sources = load_sources()
    tier1 = {n for n, s in sources.items() if s["tier"] == "1"}
    pairs = [(row, classify(to_item(row, sources), rules)) for row in load_labels(split)]
    return pairs, evaluate(pairs, tier1), rules


def write_baseline() -> None:
    """Record metrics for the current rules in rules/baseline_metrics.json (used by a regression test)."""
    out: dict = {}
    for split in ("dev", "dev2", "tune", "test2"):
        _, r, rules = run(split)
        out[split] = {
            "n": r["n"],
            "route_accuracy": r["route_accuracy"],
            "tier1_route_accuracy": r["tier1_route_accuracy"],
            "today_precision": r["today"]["precision"],
            "today_recall": r["today"]["recall"],
            "today_predicted": r["today"]["predicted"],
            "shown_precision": r["shown"]["precision"],
            "shown_recall": r["shown"]["recall"],
        }
        out["rules_version"] = rules["rules_version"]
    path = DEFAULT_RULES_PATH.parent / "baseline_metrics.json"
    path.write_text(json.dumps(out, indent=1) + "\n")
    print(f"wrote {path}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--split", choices=["dev", "dev2", "tune", "test2", "all"], default="dev")
    ap.add_argument("--rules")
    ap.add_argument("--errors", action="store_true")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write-baseline", action="store_true")
    args = ap.parse_args()
    if args.write_baseline:
        return write_baseline()
    pairs, report, rules = run(args.split, args.rules)
    if args.json:
        print(json.dumps(report, indent=2))
        return
    print(
        f"rules {rules['rules_version']}  split={args.split}  n={report['n']}  constructive={report['gold_constructive']}"
    )
    print(
        f"route accuracy {report['route_accuracy']}  tier1 {report['tier1_route_accuracy']} (n={report['tier1_n']})"
    )
    for name in ("today", "shown"):
        r = report[name]
        print(
            f"{name:6} predicted={r['predicted']:3} precision={r['precision']} recall={r['recall']} f1={r['f1']}"
        )
    print(
        "story types:",
        {k: (v["precision"], v["recall"], v["support"]) for k, v in report["story_types"].items()},
    )
    print("missed constructive by reason:", report["missed_by_reason"])
    print("false positives by gold reason:", report["false_pos_by_reason"])
    if args.errors:
        for g, c in pairs:
            gold = g["label"] == "constructive"
            if (
                (c.route == "today" and not gold)
                or (c.route == "excluded" and gold)
                or (c.route == "explore" and not gold)
            ):
                tag = (
                    "FP-today"
                    if c.route == "today"
                    else ("FP-explore" if c.route == "explore" else "MISS")
                )
                print(
                    f"{tag:10} {c.score:.2f} [{g['rejection_reason'] or 'constructive'}] {g['source'][:10]} | {g['title'][:80]} | {c.reason}"
                )


if __name__ == "__main__":
    main()

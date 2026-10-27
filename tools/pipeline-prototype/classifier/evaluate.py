"""Evaluate rules on the labeled set.

    python -m classifier.evaluate --split dev            # tune on this
    python -m classifier.evaluate --split test           # run rarely: held-out, do not tune on it
    python -m classifier.evaluate --split dev --errors   # list mistakes
"""

import argparse
import json

from .data import load_labels, load_sources, to_item
from .engine import classify, load_rules
from .metrics import evaluate


def run(split: str, rules_path: str | None = None):
    rules = load_rules(rules_path)
    sources = load_sources()
    tier1 = {n for n, s in sources.items() if s["tier"] == "1"}
    pairs = [(row, classify(to_item(row, sources), rules)) for row in load_labels(split)]
    return pairs, evaluate(pairs, tier1), rules


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--split", choices=["dev", "test", "all"], default="dev")
    ap.add_argument("--rules")
    ap.add_argument("--errors", action="store_true")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    pairs, report, rules = run(args.split, args.rules)
    if args.json:
        print(json.dumps(report, indent=2))
        return
    print(f"rules {rules['rules_version']}  split={args.split}  n={report['n']}  constructive={report['gold_constructive']}")
    print(f"route accuracy {report['route_accuracy']}  tier1 {report['tier1_route_accuracy']} (n={report['tier1_n']})")
    for name in ("today", "shown"):
        r = report[name]
        print(f"{name:6} predicted={r['predicted']:3} precision={r['precision']} recall={r['recall']} f1={r['f1']}")
    print("story types:", {k: (v["precision"], v["recall"], v["support"]) for k, v in report["story_types"].items()})
    print("missed constructive by reason:", report["missed_by_reason"])
    print("false positives by gold reason:", report["false_pos_by_reason"])
    if args.errors:
        for g, c in pairs:
            gold = g["label"] == "constructive"
            if (c.route == "today" and not gold) or (c.route == "excluded" and gold) or (c.route == "explore" and not gold):
                tag = "FP-today" if c.route == "today" else ("FP-explore" if c.route == "explore" else "MISS")
                print(f"{tag:10} {c.score:.2f} [{g['rejection_reason'] or 'constructive'}] {g['source'][:10]} | {g['title'][:80]} | {c.reason}")


if __name__ == "__main__":
    main()

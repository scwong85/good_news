from collections import Counter


def prf(tp: int, fp: int, fn: int) -> tuple[float, float, float]:
    p = tp / (tp + fp) if tp + fp else 0.0
    r = tp / (tp + fn) if tp + fn else 0.0
    f = 2 * p * r / (p + r) if p + r else 0.0
    return round(p, 3), round(r, 3), round(f, 3)


def evaluate(pairs: list[tuple[dict, "object"]], tier1_sources: set[str]) -> dict:
    """pairs: (gold label row, Classification). Route correctness is binary:
    gold constructive -> today|explore; gold rejected -> excluded."""
    gold_pos = lambda g: g["label"] == "constructive"  # noqa: E731
    shown = lambda c: c.route != "excluded"  # noqa: E731

    def tally(rows, pred):
        tp = sum(1 for g, c in rows if pred(c) and gold_pos(g))
        fp = sum(1 for g, c in rows if pred(c) and not gold_pos(g))
        fn = sum(1 for g, c in rows if not pred(c) and gold_pos(g))
        return tp, fp, fn

    def route_acc(rows):
        ok = sum(1 for g, c in rows if shown(c) == gold_pos(g))
        return round(ok / len(rows), 3) if rows else 0.0

    tier1 = [(g, c) for g, c in pairs if g["source"] in tier1_sources]
    out = {
        "n": len(pairs),
        "gold_constructive": sum(1 for g, _ in pairs if gold_pos(g)),
        "route_accuracy": route_acc(pairs),
        "tier1_route_accuracy": route_acc(tier1),
        "tier1_n": len(tier1),
    }
    for name, pred in (("today", lambda c: c.route == "today"), ("shown", shown)):
        tp, fp, fn = tally(pairs, pred)
        p, r, f = prf(tp, fp, fn)
        out[name] = {"predicted": tp + fp, "precision": p, "recall": r, "f1": f}
    types: dict[str, dict] = {}
    names = sorted(
        {t for g, _ in pairs for t in g["story_types"]}
        | {t for _, c in pairs for t in c.story_types}
    )
    for t in names:
        tp = sum(
            1
            for g, c in pairs
            if gold_pos(g) and shown(c) and t in g["story_types"] and t in c.story_types
        )
        fp = sum(
            1
            for g, c in pairs
            if shown(c) and t in c.story_types and not (gold_pos(g) and t in g["story_types"])
        )
        fn = sum(
            1
            for g, c in pairs
            if gold_pos(g) and t in g["story_types"] and not (shown(c) and t in c.story_types)
        )
        p, r, f = prf(tp, fp, fn)
        types[t] = {
            "precision": p,
            "recall": r,
            "f1": f,
            "support": sum(1 for g, _ in pairs if gold_pos(g) and t in g["story_types"]),
        }
    out["story_types"] = types
    out["missed_by_reason"] = dict(
        Counter(c.reason or "-" for g, c in pairs if gold_pos(g) and not shown(c))
    )
    out["false_pos_by_reason"] = dict(
        Counter(g["rejection_reason"] or "-" for g, c in pairs if shown(c) and not gold_pos(g))
    )
    return out

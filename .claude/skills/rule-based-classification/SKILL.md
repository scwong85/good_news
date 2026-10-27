---
name: rule-based-classification
description: Transparent rule-based constructive scoring, topic/region/story-type rules and routing, shared by the Python reference and the Dart app via rules/rules.json.
---

# Rule-based classification

- Spec: docs/classification-rules.md and docs/editorial-policy.md. Rules live in `rules/rules.json` (single source of truth), synced to `app/assets/rules/` with `scripts/sync-rules.sh`.
- Input is title + excerpt + feed categories + source metadata only. Output: score, route (`today|explore|excluded`), topics, regions, story_types, evidence_signals, and an explanation (feature, weight, matched text). No randomness, no network.
- Routing has no human in the loop, so keep `today` conservative (evidence signal or highly trusted source).
- Change rules only with an evaluation run on data/seed_labels.jsonl (dev/held-out split; never tune on the held-out set). Targets: `today` precision >= 85%, Tier-1 route accuracy >= 80%.
- Python reference and Dart implementation must agree on every labeled item (parity test).

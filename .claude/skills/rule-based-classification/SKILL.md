---
name: rule-based-classification
description: Implement and tune the transparent rule-based constructive scoring, topic/region rules, and routing.
---

# Rule-based classification

- Spec: docs/classification-rules.md and docs/editorial-policy.md.
- Weights/lexicons in versioned config (`scoring.yaml`); code is generic.
- Every decision stores an explanation: features matched, weights, route, rules_version (`ClassificationAudit`).
- The score only routes; it never publishes alone. Forced-review cases always win. Nothing is published without passing deterministic Stage 1 checks.
- Evaluate against data/seed_labels.jsonl (precision/recall/F1 per story type); do not tune on the eval split.

---
name: evaluation-and-test-writing
description: Write tests and evaluation harnesses for Good News (unit, integration, eval, safety).
---

# Evaluation and test writing

- Plan: docs/test-plan.md. Backend pytest + respx + fixture feeds; app `flutter test` + integration_test.
- Cover acceptance criteria of the current phase and the safety tests (flagged leave feed, LLM can't auto-publish, Tier 3 never auto-publishes, ingestion idempotent).
- Eval harness reports precision/recall/F1 per story type from data/seed_labels.jsonl; keep eval split separate from tuning data.
- No live network in tests.

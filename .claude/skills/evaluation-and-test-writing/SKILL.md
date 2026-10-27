---
name: evaluation-and-test-writing
description: Write tests and evaluation harnesses for Good News (Dart unit/widget/integration tests, Python reference tests, classifier evaluation and parity).
---

# Evaluation and test writing

- Plan: docs/test-plan.md. App: `flutter test`, integration_test. Reference pipeline: pytest (needs Postgres), ruff.
- No live network: mock HTTP, use fixture feeds (malformed, empty, huge, non-UTF8).
- Classifier: evaluate on data/seed_labels.jsonl with a dev/held-out split; report precision/recall/F1 per story type, route accuracy and today-precision. Dart-vs-Python parity on every labeled item.
- Cover the safety tests: disabled sources never fetched, excluded items never shown, reported items stay hidden, only excerpt shown, every story links out, no unexpected network calls.

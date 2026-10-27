# Classification rules

- `rules.json`: single source of truth (lexicons, weights, thresholds, stage-1 excludes). Spec: `../docs/classification-rules.md`.
- `golden_cases.jsonl`: inputs and expected outputs from the Python reference, for the Dart parity test. Regenerate with `python -m classifier.export_golden` (run from `tools/pipeline-prototype`).
- `baseline_metrics.json`: metrics of the current rules, used by a regression test. Regenerate with `python -m classifier.evaluate --write-baseline`.

Consumers: the Python reference classifier and the Flutter app (bundled copy in `app/assets/rules/`, kept in sync by `scripts/sync-rules.sh`). Change rules only together with an evaluation (`../docs/evaluation-report.md`).

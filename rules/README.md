# Classification rules

`rules.json` (added in Phase 2) is the single source of truth for classification: lexicons, weights, thresholds, blocklists and per-source exclude patterns. Schema and routing: `../docs/classification-rules.md`.

Consumers: the Python reference classifier (`tools/pipeline-prototype`) and the Flutter app (bundled copy in `app/assets/rules/`, kept in sync by `scripts/sync-rules.sh`).
Change rules only together with an evaluation run on `data/seed_labels.jsonl`.

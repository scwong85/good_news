# Data

`seed_labels.jsonl` holds manually labeled example articles (target: >= 100 for Phase 0). One JSON object per line:

```json
{"url": "https://...", "source": "Positive News", "title": "...", "excerpt": "...", "published_at": "2026-10-20T00:00:00Z", "label": "constructive", "story_types": ["solution"], "topics": ["environment"], "rejection_reason": null, "evidence_signals": ["data_cited"], "labeler": "name", "notes": ""}
```

- `label`: `constructive` | `rejected`. Rejected rows set `rejection_reason` from `docs/editorial-policy.md`.
- Use only real articles; store headline + short excerpt + URL only (no full text).
- Currently empty: feed hosts were unreachable from the build environment.

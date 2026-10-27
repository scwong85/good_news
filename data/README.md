# Data

`seed_labels.jsonl` holds manually labeled example articles (target: >= 100 for Phase 0). One JSON object per line:

```json
{"url": "https://...", "source": "Positive News", "title": "...", "excerpt": "...", "published_at": "2026-10-20T00:00:00Z", "label": "constructive", "story_types": ["solution"], "topics": ["environment"], "rejection_reason": null, "evidence_signals": ["data_cited"], "duplicate_group": null, "labeler": "name", "notes": ""}
```

- `label`: `constructive` | `rejected`. Rejected rows set `rejection_reason` from `docs/editorial-policy.md`.
- Use only real articles; store headline + short excerpt + URL only (no full text).
- `duplicate_group` (optional): same story seen in several feeds, used to evaluate deduplication.
- Current file: 102 real items from 10 feeds (first items in each feed on 2026-10-27; 48 constructive, 54 rejected). Labels are a **draft by Claude** against `docs/editorial-policy.md`, notes mark borderline cases. A human editor should review them before they are used for evaluation or training.
- Excerpts are truncated to 200 characters from the RSS description.

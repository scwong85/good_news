---
name: deduplication
description: Duplicate-story detection for Good News: canonical URL, normalized-title similarity, cluster/primary selection. Embeddings are a future option.
---

# Deduplication

- Implemented in `app/lib/pipeline/dedupe.dart` (+ `selection/dedupe_service.dart`): canonical URL (unique) -> title tokens (lowercase, stopwords out, plural stemming) -> tier A Jaccard >= 0.6, tier B IDF cosine >= 0.30 with >= 2 shared rare words, 3-day window. Precision first: a false merge hides a story.
- `cluster_id` = earliest member's id; the selector takes one story per cluster. A day's picks never contain two articles from one cluster.
- Test with the `duplicate_group` pairs in data/seed_labels.jsonl and require zero false merges (known miss: the mussel pair). Add labeled duplicate pairs before tuning thresholds.
- Must be cheap enough for on-device use; embeddings only in the future web export if needed.

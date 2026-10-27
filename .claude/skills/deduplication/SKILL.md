---
name: deduplication
description: Duplicate-story detection for Good News: canonical URL, normalized-title similarity, cluster/primary selection. Embeddings are a future option.
---

# Deduplication

- Order: canonical URL (unique) -> normalized-title similarity (lowercase, strip punctuation/stopwords, token-set Jaccard or similar, same-day or short window) -> (future) embedding cosine.
- Keep the highest-ranked article as primary (score, then source trust, then earliest); mark alternates with a shared `cluster_id`. A day's picks never contain two articles from one cluster.
- Test with the `duplicate_group` pairs in data/seed_labels.jsonl and with similar-but-different stories (no false merges).
- Must be cheap enough for on-device use; embeddings only in the future web export if needed.

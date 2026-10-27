---
name: deduplication
description: Deduplicate articles by canonical URL, title similarity and embeddings; build clusters.
---

# Deduplication

- Order: canonical URL (unique constraint) -> normalized-title similarity (e.g. token-set ratio) -> embedding cosine >= 0.90 (configurable).
- Compare only against recent articles (time window) to bound cost.
- Create a `DuplicateCluster`; primary = highest quality_score, tie-break by source trust then earliest published. Link alternates, set `duplicate_of_id`.
- Runs async. Daily digest must never contain two articles from one cluster.
- Tests: known duplicate pairs and known near-misses (similar topic, different story).

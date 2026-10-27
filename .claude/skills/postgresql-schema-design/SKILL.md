---
name: postgresql-schema-design
description: Design PostgreSQL schemas, indexes, constraints and migrations for Good News.
---

# PostgreSQL schema design

- Source of truth: docs/data-model.md. Update it in the same change as any migration.
- Use constraints (unique canonical_url, check trust_score between 0 and 1, enum-like checks on status) not just app validation.
- Indexes: (status, published_at desc), GIN on topics/regions/search_vector. Full-text search via `SearchVector` and a stored tsvector column.
- Migrations must be reversible where possible and safe to run on populated tables (no long locks; add nullable, backfill, then constrain).
- Embeddings: start as float arrays; move to pgvector only if scale requires it (record in decision-log).

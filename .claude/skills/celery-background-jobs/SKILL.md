---
name: celery-background-jobs
description: Celery + Redis tasks, beat schedules, retries and idempotency for ingestion, classification and dedup.
---

# Celery background jobs

- Tasks are idempotent and take ids, not objects. Use `acks_late`, bounded retries with backoff, and time limits.
- Beat schedule: per-source fetch honoring `fetch_interval_minutes`; digest generation; retention analytics.
- Chain: ingest -> normalize -> deduplicate (async) -> classify -> route (docs/pipeline-hooks.md `after_ingestion`).
- Separate queues: `ingestion`, `classification`, `embeddings` (heavy, optional), `default`.
- In tests use `CELERY_TASK_ALWAYS_EAGER`.

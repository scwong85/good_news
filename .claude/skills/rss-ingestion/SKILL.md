---
name: rss-ingestion
description: Build or modify RSS/API ingestion for Good News: fetching, parsing, canonicalizing URLs, normalizing, idempotent storage. Use for any ingestion worker work.
---

# RSS ingestion

- Fetch with `httpx` (timeout, retries with backoff, conditional GET via ETag/Last-Modified), parse with `feedparser`. Send `INGESTION_USER_AGENT`.
- Implementation lives in `backend/ingestion/` (`urls.py`, `normalize.py`, `fetch.py`, `hooks.py`, `service.py`). Run `before_ingestion` checks (docs/pipeline-hooks.md): source active, licensing note, robots, rate limit.
- Never crash on malformed feeds: record an `IngestionRun` with status and error, continue to next source.
- Store the raw payload (`RawItem`) separately from the normalized `Article`.
- Canonicalize URLs: lowercase host, strip fragments and tracking params (utm_*, fbclid, gclid), upgrade http to https, drop trailing slash (do not fetch article pages to resolve `rel=canonical`; see decision log #15). Unique on canonical_url so reruns never duplicate.
- Normalize title (whitespace, HTML entities), date (UTC; reject missing), language, regions. Keep only a short excerpt (<= ~300 chars); never store full article body for display.
- Tests use fixture feeds, never the live network.

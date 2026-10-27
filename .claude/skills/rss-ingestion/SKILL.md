---
name: rss-ingestion
description: Fetching, parsing and normalizing RSS/Atom feeds for Good News (Dart on-device implementation; Python reference in tools/pipeline-prototype).
---

# RSS ingestion

- On-device (Dart) spec: docs/architecture.md 'Fetch-on-open flow'; port behaviour from the Python reference in `tools/pipeline-prototype/ingestion/` (`urls.py`, `normalize.py`, `fetch.py`, `service.py`) and its tests.
- Fetch: identify the app via User-Agent; timeouts, size cap, conditional GET (ETag/Last-Modified), small retry on transport/5xx, back off on 429 with Retry-After. Never crash on malformed feeds; record status per source and continue.
- Canonicalize URLs: lowercase host, http->https, drop default ports, fragments and tracking params (utm_*, fbclid, gclid, mc_*...), sort query, strip trailing slash. Do not fetch article pages (no rel=canonical resolution).
- Normalize: strip HTML/entities, NFC, collapse whitespace, remove WordPress 'The post ... appeared first on' boilerplate, excerpt <= 300 chars on a word boundary, UTC dates (skip missing, clamp far-future), language fallback to the source's, topics from feed categories.
- Idempotent: unique canonical_url; reruns create nothing.
- Tests use fixture feeds, never the live network.

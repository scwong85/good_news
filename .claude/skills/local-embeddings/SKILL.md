---
name: local-embeddings
description: (FUTURE, not in the current plan) Generate and use local sentence embeddings (no external API) for deduplication and similarity.
---

# Local embeddings (future)

Only for the Python reference or the future web export; not part of the on-device app. Python prototype only.

- Optional extra: `uv sync --extra embeddings` (sentence-transformers). Default model: a small multilingual MiniLM; record the exact model and version in the decision log.
- Embed normalized `title + summary/excerpt`; store with model id so vectors from different models are never compared.
- Run in the `embeddings` Celery queue; cache model load per worker process.
- Must degrade gracefully: if the extra is missing, URL and title-similarity dedup still work.

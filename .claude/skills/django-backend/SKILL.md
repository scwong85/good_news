---
name: django-backend
description: Django 5 + DRF conventions for the Good News backend: apps layout, models, admin, serializers, testing.
---

# Django backend

- Layout: `backend/config/` (settings, celery) and apps `sources, articles, ingestion, classification, review, feed`.
- Models follow docs/data-model.md; UUID pks; status changes only through a service function that writes `ArticleStatusEvent`.
- Settings from env (see .env.example) via dj-database-url; no secrets in code.
- Admin is the Phase 1/2 review UI: list filters on status/source/score, actions approve/reject/archive, read-only classification explanation.
- DRF: cursor pagination, serializers never expose full text, public endpoints throttled.
- Run: `uv run pytest`, `uv run ruff check .`, `uv run mypy .` from backend/.

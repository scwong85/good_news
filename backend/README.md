# Backend (Django + DRF + Celery)

Phase 1 (ingestion MVP) is implemented. Classification (Phase 2) and deduplication (Phase 3) plug in through `ingestion.hooks.register_after_ingestion`.

## Apps
| App | Purpose |
|---|---|
| `sources` | `Source` model, admin (fetch now / enable / disable), `seed_sources` command |
| `ingestion` | `IngestionRun`, `RawItem`; URL canonicalization, normalization, fetch (robots, ETag, retry), hooks, service, Celery tasks, `ingest` command |
| `articles` | `Article`, `ArticleStatusEvent`; status state machine (`transition`) with `before_publish` checks |
| `review` | `ReviewDecision`, review queue admin, `review_article` service |
| `feed` | Server-rendered feed at `/`, read-only JSON API at `/api/v1/` |

## Run locally
```
docker compose up -d db redis        # or any Postgres 16 + Redis
cd backend
uv sync
uv run python manage.py migrate
uv run python manage.py seed_sources            # from docs/source-allowlist.csv
uv run python manage.py createsuperuser
uv run python manage.py ingest                  # all active sources (respects interval)
uv run python manage.py ingest --force --backfill-pages 8 --max-age-days 0   # backfill
uv run python manage.py runserver               # / feed, /admin review queue
```
Review: Admin -> "Review queue" -> select articles -> "Approve and publish" or "Reject: <reason>". Only published articles appear in the feed and API.

Scheduled ingestion: `celery -A config worker -l info` and `celery -A config beat -l info` (beat runs `ingest_due_sources` every 5 minutes).

## Checks
```
uv run ruff check . && uv run ruff format --check .
uv run pytest            # needs Postgres (DATABASE_URL, default postgres://goodnews:goodnews@localhost:5432/goodnews)
```
Tests never use the live network (`respx` mocks + generated fixture feeds in `tests/`).

# Pipeline prototype (Python / Django), reference only

This is the Phase 1 implementation from the original server-based plan. **It is not part of the shipped product.** The product is the Flutter app in `../../app`, which fetches feeds on the user's device (see `../../docs/architecture.md`).

It is kept because it is working, tested code that we use for:
1. **Developing and evaluating classification rules** against `../../data/seed_labels.jsonl` quickly, before porting them to Dart (Phase 2 in `../../docs/implementation-plan.md`).
2. **Real feed behaviour**: it already handles canonicalization, normalization, malformed feeds, pagination/backfill and robots.txt, and its tests are a reference for the Dart port.
3. **The future web milestone**: a scheduled job can reuse this pipeline to export static JSON for the Flutter web build (`../../docs/static-feed-contract.md`).

Nothing here is deployed. The original server data model is in [`DATA_MODEL.md`](DATA_MODEL.md).

## Apps
| App | Purpose |
|---|---|
| `sources` | `Source` model, admin, `seed_sources` command (reads `docs/source-allowlist.csv`) |
| `ingestion` | `IngestionRun`, `RawItem`; URL canonicalization, normalization, fetch (robots, ETag, retry), hooks, service, `ingest` command (Celery tasks are optional) |
| `articles` | `Article`, `ArticleStatusEvent`, status state machine |
| `review` | `ReviewDecision`, admin review queue |
| `feed` | Server-rendered feed at `/` and read-only JSON API |

## Run locally
```
cd tools/pipeline-prototype
docker compose up -d db            # or any local Postgres 16
uv sync
uv run python manage.py migrate
uv run python manage.py seed_sources
uv run python manage.py ingest --force --backfill-pages 8 --max-age-days 0
uv run python manage.py createsuperuser && uv run python manage.py runserver
```
## Checks
```
uv run ruff check . && uv run ruff format --check .
uv run pytest        # needs Postgres (default postgres://goodnews:goodnews@localhost:5432/goodnews)
```
Tests never use the live network.

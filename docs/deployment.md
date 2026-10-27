# Deployment

**MVP target: Fly.io** (see decision log). AWS ECS/Fargate + S3 + CloudFront is the later option.

## Environments
`local` (docker compose) -> `staging` -> `production`.

## Components
Django web (gunicorn), Celery worker, Celery beat, Postgres 16, Redis 7 (hosted on Fly.io); Flutter web build as static files on **GitHub Pages**; Android APK/AAB via Play Store.

## Requirements
Encryption in transit and at rest; backups and restore drill for Postgres; secrets via platform secret store; minimal logging of user data; privacy-friendly opt-in analytics.

## GitHub Pages (Flutter web)
Project site at `https://<user>.github.io/good_news/`: build with `--base-href /good_news/`, hash URLs, `404.html` copy of `index.html`, API base URL via `--dart-define`. Pages is static only, so the API stays on Fly.io with CORS allowing the Pages origin. Publishing workflow is intentionally **not** created yet.

## Release checks (`before_deploy`)
Tests, migrations dry-run, lint, security checks (dependency audit), smoke tests.
## Post-deploy (`after_deploy`)
Health endpoint OK; one test ingestion run succeeds; `/feed/today` returns 200.

## Open items
Takedown/contact address; domain; CI/CD pipeline (intentionally **not** created yet).

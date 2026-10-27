# Good News Aggregator

A calm, mobile-first Flutter app (Android + web) that aggregates credible constructive news from vetted sources, with transparent rule-based classification and human editorial review.

- Product and editorial docs: [`docs/`](docs/)
- Contributor/agent guide: [`CLAUDE.md`](CLAUDE.md)
- Status: Phase 0 (editorial foundation). See [`docs/decision-log.md`](docs/decision-log.md).

## Layout
```
backend/    Django + DRF + Celery (Phase 1+)
app/        Flutter app: Android + web (Phase 4+), web hosted on GitHub Pages
docs/       Shared project context
data/       Labeled seed data
scripts/    Dev tooling
.claude/    Project skills and dev hooks
```

## Local infra
```
cp .env.example .env
docker compose up -d db redis
```

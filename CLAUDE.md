# Good News Aggregator: project guide

Calm, trustworthy aggregator of credible *constructive* news. Read `docs/product-brief.md` first.

## Shared context (keep these current)
`docs/`: product-brief, editorial-policy, source-allowlist.csv, api-contracts, data-model, classification-rules, pipeline-hooks, decision-log, test-plan, deployment.

## Non-negotiables
- Curated allowlist only; Tier 3 / broad discovery never auto-publishes.
- No external LLM dependency; LLM output is a draft, never auto-published.
- Never republish full articles; headline + short excerpt/summary + attribution + canonical link.
- Every classification has a stored explanation. Reviewer can override anything.
- Ingestion must be idempotent (no duplicate canonical URLs on rerun).
- Anonymous reading; minimal user data.
- Don't add CI workflows until the owner asks.

## Stack
Python 3.12 + uv, Django 5 + DRF, Celery + Redis, PostgreSQL 16, Flutter (one codebase: Android app + web app on GitHub Pages) in `app/`. Django API hosted on Fly.io for MVP (GitHub Pages is static-only).

## Workflow
- Follow phase order in `docs/decision-log.md`; update the tracker and log decisions/open questions there.
- Skills in `.claude/skills/` cover each area. A Stop hook runs `scripts/dev-check.sh` (lint/tests once code exists).
- Dev commands: `docker compose up -d db redis`; backend `cd backend && uv run pytest`; app `cd app && flutter test`.
- Tests never hit the live network; use fixture feeds.

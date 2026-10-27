# Decision Log & Phase Tracker

## Decisions
| # | Decision | Date |
|---|---|---|
| 1 | Start with a curated allowlist, not broad crawling | 2026-10-27 |
| 2 | **Revised:** single Flutter codebase for Android + web (replaces Next.js PWA); iOS later | 2026-10-27 |
| 3 | No external LLM at launch | 2026-10-27 |
| 4 | Deterministic rules + optional local models | 2026-10-27 |
| 5 | LLM for enrichment only, never auto-publish | 2026-10-27 |
| 6 | Do not republish full articles | 2026-10-27 |
| 7 | Optimize for trust and calm, not engagement | 2026-10-27 |
| 8 | Editorial decisions and feedback are training data | 2026-10-27 |
| 9 | Stack: Python 3.12 + uv, Django 5 + DRF, Celery + Redis, Postgres 16, Flutter app in `app/` | 2026-10-27 |
| 10 | MVP hosting target: Fly.io (AWS ECS later) | 2026-10-27 |
| 11 | Hooks split: pipeline hooks in app code; Claude Code hooks only for dev workflow | 2026-10-27 |
| 12 | No CI workflow yet (explicit request) | 2026-10-27 |
| 13 | Web app hosted on GitHub Pages (static); Django API hosted separately on Fly.io with CORS; hash routing + base-href | 2026-10-27 |

## Open questions / blockers
- **Network:** the cloud environment's network policy returns 403 for feed hosts (positive.news, reasonstobecheerful.world, goodnewsnetwork.org, etc.). Feed URLs in `source-allowlist.csv` are **unverified** (`feed_verified=false`, `active=false`) and `data/seed_labels.jsonl` is empty until access is allowed.
- Licensing/terms review per source not done.
- Contact address for takedown requests.
- Project name/domain.

## Phase tracker
| Phase | Status |
|---|---|
| 0 Editorial foundation | In progress: policy, rules and schema done; feed verification and 100 labels blocked |
| 1 Ingestion MVP | Not started |
| 2 Deterministic classification | Not started |
| 3 Deduplication | Not started |
| 4 Flutter app MVP (Android + web) | Not started |
| 5 Feedback and retention | Not started |
| 6 Local ML | Not started |
| 7 Optional LLM | Not started |
| 8 Native polish (push, offline, widget, iOS) | Not started |

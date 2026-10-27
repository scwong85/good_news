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
- **Sources:** feeds checked 2026-10-27: 10 of 11 return valid RSS. Squirrel News feed 404s and stays inactive until a working feed is found. 10 sources are active, which meets the Phase 0 criterion of >= 10.
- **Labels:** `data/seed_labels.jsonl` has 102 draft labels from Claude; need human review. Upworthy (2/10) and YES! Magazine (0/8) yielded few constructive items, so consider lowering their trust or disabling them.
- robots.txt allows the feed paths of the 9 sites checked (Good Good Good's and Squirrel News's robots.txt were not checked); per-source terms/licensing review is still pending.
- Licensing/terms review per source not done.
- Contact address for takedown requests.
- Project name/domain.

## Phase tracker
| Phase | Status |
|---|---|
| 0 Editorial foundation | Mostly done: policy, rules, schema, 10 verified feeds, 102 draft labels. Remaining: human label review, licensing review |
| 1 Ingestion MVP | Not started |
| 2 Deterministic classification | Not started |
| 3 Deduplication | Not started |
| 4 Flutter app MVP (Android + web) | Not started |
| 5 Feedback and retention | Not started |
| 6 Local ML | Not started |
| 7 Optional LLM | Not started |
| 8 Native polish (push, offline, widget, iOS) | Not started |

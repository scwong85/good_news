# Decision Log & Phase Tracker

## Decisions
Status: **active**, or **superseded by #n**.

| # | Decision | Date | Status |
|---|---|---|---|
| 1 | Start with a curated allowlist, not broad crawling | 2026-10-27 | active |
| 2 | Launch as web/PWA; Flutter native after retention | 2026-10-27 | superseded by #18 |
| 3 | No external LLM at launch | 2026-10-27 | active |
| 4 | Deterministic rules + optional local models | 2026-10-27 | active (local models are a future milestone) |
| 5 | LLM for enrichment only, never auto-publish | 2026-10-27 | active (future milestone) |
| 6 | Do not republish full articles | 2026-10-27 | active |
| 7 | Optimize for trust and calm, not engagement | 2026-10-27 | active |
| 8 | Editorial decisions and feedback are training data | 2026-10-27 | active |
| 9 | Stack: Django + Celery + Postgres + Flutter | 2026-10-27 | superseded by #18, #19 |
| 10 | MVP hosting target: Fly.io | 2026-10-27 | superseded by #19 |
| 11 | Hooks split: pipeline hooks in app code; Claude Code hooks only for dev workflow | 2026-10-27 | active (see `pipeline-hooks.md`) |
| 12 | No CI workflow yet (explicit request) | 2026-10-27 | active |
| 13 | Web hosted on GitHub Pages (static) with a separate API | 2026-10-27 | superseded by #19, #20 |
| 14 | Prototype lists are JSONField, not ArrayField | 2026-10-27 | active (prototype only) |
| 15 | Do not fetch article pages; excerpt from RSS only | 2026-10-27 | active |
| 16 | Canonical URLs: http->https, strip fragments, tracking params, trailing slash | 2026-10-27 | active |
| 17 | Phase 1 ingested items were all `pending_review` | 2026-10-27 | superseded by #21 |
| 18 | **One Flutter codebase; Android first.** Web later. | 2026-10-27 | active |
| 19 | **Client-side first:** the app fetches the curated feeds itself when opened, parses/classifies/de-dupes/selects on device. No server we operate, no background fetch. | 2026-10-27 | active |
| 20 | **Web is a future milestone** that reads pre-built static JSON (browsers block direct feed reads: 1 of 10 feeds allows CORS, tested 2026-10-27). Hosting (GitHub Pages or Netlify) and the scheduled export are decided then. | 2026-10-27 | active |
| 21 | No human review at runtime. Control comes from the allowlist, versioned tested rules, offline evaluation, local reporting; human review returns with the web export. Routes: `today`, `explore`, `excluded`. | 2026-10-27 | active |
| 22 | Daily picks: `stories_per_day` 5-10 (default 5), fixed per local day, diversity caps (2 per source, 3 per topic) | 2026-10-27 | active |
| 23 | Classification rules live in a shared `rules/rules.json`; Python reference implementation + Dart port with a parity test | 2026-10-27 | active |
| 24 | The Django/Postgres/Celery work moved to `tools/pipeline-prototype/` as a reference (rules evaluation, future web export). Not deployed. | 2026-10-27 | active |
| 25 | State management Riverpod, storage Drift/SQLite, routing go_router (subject to change at Phase 3 if a better fit is found) | 2026-10-27 | proposed |

## Open questions
- Human review of the 102 draft labels, and growing the set (target >= 300) for held-out evaluation.
- Per-source terms/licensing review for direct client-side fetching by end users.
- Contact address for takedown requests; privacy policy hosting (needed for the Play Store).
- Project name, application id and Play Store account.
- Web milestone: GitHub Pages vs Netlify, and the scheduler for the export job.
- Squirrel News feed 404s; find a working feed or drop the source.
- Flutter SDK is not installed in the cloud session; Phase 3 needs it (or a CI-less local setup).

## Phase tracker (see `implementation-plan.md`)
| Phase | Status |
|---|---|
| 0 Editorial foundation | Mostly done: policy, 10 verified feeds, 102 draft labels. Remaining: human label review, terms review |
| 1 Python reference pipeline | Done (reference only, `tools/pipeline-prototype`) |
| 2 Shared classification rules | Not started |
| 3 Flutter app foundation (Android) | Not started |
| 4 On-device classification, de-dup, daily selection | Not started |
| 5 Android UI | Not started |
| 6 Android hardening and release | Not started |
| Future A: Web via static JSON | Future |
| Future B: Remote rules and editorial loop | Future |
| Future C: Optional extras (ML, LLM, iOS, server) | Future |

# Pipeline Hooks (app-level contracts)

Named extension points in the on-device pipeline (`app/lib/pipeline`). Implemented as plain functions/interfaces so they can be unit-tested. (Dev-workflow hooks for Claude Code are separate: `.claude/settings.json`.)

| Hook | Runs | Checks / actions |
|---|---|---|
| `before_fetch` | Before each source request | Source enabled by user; not in `backoff_until`; cache older than TTL (30 min); network available |
| `after_fetch` | After a source responds | Record status/ETag/Last-Modified; on failure increment `consecutive_failures` and set backoff (honor `Retry-After`); isolate errors per source |
| `after_normalize` | Per item | Stage-1 filters; canonicalize URL; skip if URL already stored |
| `after_classify` | Per item | Store route, scores and explanation with `rules_version` (implemented: `ClassificationService`; stale rows are re-classified after the refresh) |
| `before_select` | Before creating the day's picks | Drop hidden, seen, previously picked and out-of-window stories; enforce enabled sources (implemented in `DailyPicksService`) |
| `after_feedback` | After local feedback | `not_credible` hides the story and lowers its source's rank on this device |
| `before_release` | Release process | Tests, `flutter analyze`, rules sync check, parity test, manual QA checklist |
| `after_release` | After a release | Smoke test on a clean device: fetch, Today, offline |

Future (not built): `before_export` / `after_export` for the web export job; `before_llm_call` / `after_llm_call` if LLM enrichment is ever added (drafts only, human-reviewed).

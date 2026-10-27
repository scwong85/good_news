# Implementation Plan (client-side first)

Supersedes the original server-based plan (see `decision-log.md`). Phases run in order; each has acceptance criteria that must be demonstrated by tests or a documented manual check. **Web hosting and any server components are future milestones that start only after Phases 2 to 6 are done and tested.**

## Phase 0: Editorial foundation (done)
Editorial policy, story types and rejection reasons, 10 verified sources (`source-allowlist.csv`), 102 draft labels (`data/seed_labels.jsonl`).
Remaining: human review of the draft labels; per-source terms review.

## Phase 1: Python reference pipeline (done, reference only)
`tools/pipeline-prototype/`: RSS ingestion, canonicalization, normalization, idempotent storage, Django admin review queue, 66 tests. Kept as a reference and for the future web export.

## Phase 2: Shared classification rules
**Objective:** a transparent, versioned rules file with measured accuracy, before any Dart code depends on it.
Tasks:
- Review/finalize labels; split into dev and held-out test sets (keep test untouched while tuning). Grow to >= 300 labeled items if feasible.
- Define `rules/rules.json` (schema in `classification-rules.md`): lexicons, weights, thresholds, blocklists, per-source exclude patterns (for example roundups), topic and region rules, story-type rules.
- Implement the reference classifier in Python (`tools/pipeline-prototype`) plus an evaluation script (precision/recall/F1 per story type, route accuracy).
- Calibrate thresholds for `today` and `explore` routes.
Deliverables: `rules/rules.json`, reference classifier, evaluation report, explanation output for every decision.
Acceptance: on the held-out set, `today` route precision >= 85% and Tier-1 route accuracy >= 80%; every classification has an explanation; rules are deterministic.

## Phase 3: Flutter app foundation (Android)
Tasks: create the Flutter project in `app/` (Android target; keep code web-compatible); domain models; `StorySource` interface and `DirectRssStorySource`; HTTP client with timeouts, size cap, conditional GET, retry/backoff; RSS/Atom parsing; URL canonicalization and normalization (port of the Python behaviour); Drift schema; bundled source list generated from `source-allowlist.csv`.
Deliverables: ingestion working end-to-end into SQLite on an Android emulator/device.
Acceptance: fetches all enabled sources in parallel; malformed or failing feeds are isolated and recorded; reruns create no duplicates; works offline from cache; unit tests with fixture feeds pass (`flutter test`).

## Phase 4: On-device classification, de-duplication and daily selection
Tasks: Dart port of the classifier reading `rules.json`; parity test against the Python reference on the whole labeled set; title-similarity de-duplication (normalized tokens, same-day window); ranker; diversity-aware daily selector with `stories_per_day` 5-10; stable picks per local day; seen tracking.
Acceptance: Dart and Python classifiers agree on >= 99% of labeled items (route) and score within tolerance; the held-out metrics from Phase 2 still hold; no duplicate story in a day's picks (tested with the labeled duplicate groups); selecting 5-10 picks is deterministic for a given cache and day.

## Phase 5: Android UI
Screens: Today, Explore (topic/region/story-type filters and search over cached articles), Story detail ("why this story was included", original-link button, save, share), Saved (offline), Preferences (stories per day 5-10, topics, regions, sources on/off, sensitivity). Fetch-on-open with cached-first rendering, pull to refresh, empty/error/offline states. Accessibility (TalkBack, text scaling, contrast), calm design.
Acceptance: cached Today renders in < 1 s after launch; fresh fetch completes or times out gracefully within 15 s; every story links to the original publisher; works on phone and tablet; widget tests and an emulator integration test pass.

## Phase 6: Android hardening and release
Tasks: local-only feedback and report-to-hide; optional local daily reminder notification (opt-in, no server); privacy policy and takedown/contact page; Play Store listing and data-safety form; release signing; performance and battery check; crash reporting only if opt-in.
Acceptance: release build installs and runs from a clean device; privacy declarations are accurate (no data collected); all safety tests in `test-plan.md` pass; manual QA checklist signed off.

## Future milestone A: Web via static JSON (starts after Phase 6)
Tasks: `export_static` job in the prototype producing the files in `static-feed-contract.md`; scheduled run (GitHub Actions cron or equivalent, added only when the owner asks); static hosting on GitHub Pages or Netlify; `StaticJsonStorySource`; Flutter web build (`--base-href`, hash routing); privacy page on the same host.
Acceptance: web app loads the latest export in < 2 s on a typical mobile connection; same selection logic and UI as Android; stale-export handling.

## Future milestone B: Remote rules and editorial loop
Remote `rules.json` and source/blocklist updates with signature or hash checks; offline editorial review of samples and user reports; reviewed-list file or PR workflow.

## Future milestone C: Optional extras
On-device or local ML classifier, embeddings-based de-duplication, LLM-enriched summaries (draft only, human-reviewed, never required), iOS, push via a server, accounts and sync, a hosted backend if the product outgrows client-side.

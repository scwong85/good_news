# Test Plan

**App (Dart/Flutter):** `flutter test` (unit + widget), `integration_test` on an emulator, `flutter analyze`, `dart format`.
**Reference pipeline (Python):** pytest (Postgres required), ruff. Used for rules evaluation and the Dart parity test.
Current Dart suite: 226 tests (`flutter test`) covering the pipeline, fetcher, database (including the v1 -> v2 migration), ingestion, classification parity and metrics, de-duplication, ranking, selection and the picks service; `dart run tool/live_ingest.dart` is a manual live-feed check, not part of the suite.
Tests never use the live network: HTTP is mocked and feeds come from fixtures (`app/test/fixtures/feeds/`, generated or snapshotted from real feeds, including malformed, empty, huge and non-UTF8 cases).

## Unit (Dart)
URL canonicalization; date parsing; RSS/Atom parsing; title/excerpt normalization; language detection fallback; Stage-1 filters; classifier features and routing; topic/region/story-type rules; title-similarity de-duplication; ranker; daily selector (count 5-10, per-source/topic caps, stability within a day, extension when the setting increases, local midnight rollover); retention pruning.

## Integration
Fetch-on-open with mocked HTTP: parallel fetch, per-source isolation, timeouts, size cap, 304 handling, `Retry-After` backoff, offline start, idempotent reruns; cache-first rendering; migrations (Drift schema upgrades with data).

## Parity and evaluation
- Dart classifier output equals the Python reference on every item in `data/seed_labels.jsonl` (route equal, score within 1e-6).
- Held-out metrics (`test2`): `today` precision >= 85%, Tier-1 route accuracy >= 80% (currently 92.3% / 73.3%); per-story-type precision/recall/F1 reported. A regression test compares against `rules/baseline_metrics.json`.
- De-duplication: all `duplicate_group` pairs in the labeled set detected; no false merges across different stories in the set.
- Re-review a random sample of live picks manually after every rules change.

## UI
Widget tests for Today, Explore, Story, Saved, Preferences (empty/loading/error/offline states). Accessibility checks: TalkBack labels, 200% text scale, contrast. Integration test for first launch -> picks -> open story -> save -> offline reopen.

## UI (Phase 5)
Widget tests drive the whole app on in-memory SQLite and a fake web (`test/support/app_harness.dart`): Today (first open, gathering, cache-first, offline, partial failure, deadline, refresh politeness, stories per day), Explore (search, filters, de-duplication), Story (why included, open original, share, save, seen), Saved (offline, survives cleanup), Settings and About. Accessibility: tap-target, label and contrast guidelines in light and dark, semantics of cards, slider and refresh button. Responsive: phone vs tablet navigation, readable column width, no overflow at 100% to 200% text on 320 to 1000 px. `test/app_flow_test.dart` runs the reader journey; `integration_test/app_test.dart` runs the same journey on a device. `SCREENSHOT_DIR=<dir> flutter test test/screenshots` renders the screens to PNG for visual review.

## Safety
- The app never displays more than the stored excerpt and never fetches article pages.
- Every story links to the original publisher.
- A reported/hidden story never reappears on that device (`test/selection/feedback_test.dart`, `test/ui/hide_report_test.dart`).
- A disabled source is never requested.
- Excluded and blocklisted items never appear in Today or Explore.
- No network calls other than feed requests (verify with a proxy in manual QA). `test/policy_test.dart` guards the manifest (INTERNET only, no services/receivers, backup off), banned analytics/ads/background packages, and that the bundled privacy policy equals `docs/legal/`.

## Performance budgets (verify on a mid-range device)
Cached launch to content < 1 s; refresh of 10 sources completes or times out within 15 s; memory stays reasonable with 30 days of articles.

## Phase acceptance
Each phase's acceptance criteria in `implementation-plan.md` must be demonstrated by a test or documented manual check.

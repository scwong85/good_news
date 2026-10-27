# Test Plan

**Backend:** pytest + pytest-django, `respx` for HTTP mocking, fixture feeds in `backend/tests/fixtures/feeds/` (include malformed XML, empty feed, huge feed, non-UTF8).
**App:** `flutter test` (unit + widget), integration_test for key flows; web smoke via Playwright against the built Pages bundle.
**Lint/type:** ruff, mypy (backend); `flutter analyze`, `dart format` (app).

## Unit
URL canonicalization; date parsing; language detection; keyword scoring; topic rules; region inference; duplicate detection; feed ranking; API authorization.

## Integration
RSS ingestion from fixtures; normalization; classification routing; review approval flow; dedup workflow; feedback recording; digest generation; ingestion idempotency (re-run creates no duplicates).

## Evaluation
Labeled eval set; precision/recall/F1 per story type; duplicate-detection performance; false-positive/false-negative constructive rates; weekly random sample review of published stories.

## Safety
Paywalled articles not fully republished; flagged articles leave the feed; LLM output cannot auto-publish; removing a source stops future ingestion; user data deletion works; Tier 3 never auto-publishes.

## Phase acceptance
Each phase's acceptance criteria (see `decision-log.md` phase tracker) must be demonstrated by a test or a documented manual check.

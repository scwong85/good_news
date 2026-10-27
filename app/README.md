# App (Flutter, Android first)

The shipped product. It fetches the curated feeds on the device when opened and does all processing locally. Architecture: [`../docs/architecture.md`](../docs/architecture.md). Plan: [`../docs/implementation-plan.md`](../docs/implementation-plan.md).

**Status: Phases 3 and 4 are implemented** (ingestion, on-device classification, de-duplication, ranking and daily picks). The UI is only a harness screen (`lib/features/debug/`); the real screens (Today, Explore, Story, Saved, Preferences) are Phase 5.

## What exists
```
lib/
  domain/        Source
  pipeline/      canonicalize_url, dates, feed_parser (tolerant), normalize, rules, classifier, dedupe  (pure Dart)
  classification/ ClassificationService (classify on insert, re-classify after a rules update)
  selection/     rank, daily_selector (pure); DedupeService, PreferencesRepository, DailyPicksService
  data/http/     FeedFetcher: conditional GET, timeout, size cap, retry, Retry-After
  data/sources/  StorySource interface, DirectRssStorySource
  data/db/       Drift tables + AppDatabase (schema v2: sources, articles, daily_picks, seen, preferences); generated app_database.g.dart is committed
  ingestion/     IngestionService: parallel refresh, TTL, backoff, retention, per-source isolation
  core/          Riverpod providers, bundled-asset loading
  features/debug Phase 3 harness screen
assets/          sources.json (generated), rules/rules.json (synced copy)
test/            pipeline, classification (parity + metrics), selection, data, ingestion, migration, widget and asset tests; fixtures/feeds, golden_urls.json
tool/            live_ingest.dart: run the real pipeline against the live feeds
```

## Commands
Flutter is at `/opt/flutter/bin` in the cloud session (add it to `PATH`).
```
flutter pub get
flutter analyze
flutter test                          # 226 tests, no network
dart run tool/live_ingest.dart [N]    # live feeds, in-memory DB, two passes, then today's N picks
dart run build_runner build --delete-conflicting-outputs   # after editing data/db/tables.dart
# After a schema change: bump schemaVersion, then
dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/generated_migrations/   # and add a migration test
python3 ../scripts/sync-sources.py    # regenerate assets/sources.json from docs/source-allowlist.csv
../scripts/sync-rules.sh              # copy ../rules/rules.json into assets/rules/
python3 ../scripts/export-url-golden.py   # regenerate test/fixtures/golden_urls.json from the Python reference
```

## Not verified here
The cloud session has no Android SDK (`dl.google.com` is not reachable), so the app has **not been built as an APK or run on an emulator/device**. Verification so far is `flutter analyze`, the unit/widget tests, and the live-feed script. Application id is the placeholder `com.example.good_news`. Never commit signing keys.

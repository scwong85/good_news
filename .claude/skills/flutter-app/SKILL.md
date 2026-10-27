---
name: flutter-app
description: Flutter app for Good News (Android first): architecture, layers, UI screens, state, storage, fetch-on-open. Use for any app/ work.
---

# Flutter app

- Spec: docs/architecture.md, docs/implementation-plan.md (Phases 3-6), docs/data-model.md. Code in `app/`.
- Target Android first; keep `pipeline/` pure Dart (no Flutter imports) and the rest web-compatible (no `dart:io` outside conditional imports) so the web build is possible later. Do not build or host the web app until the owner starts that milestone.
- Layers: `domain`, `data/sources` (StorySource interface), `data/db` (Drift/SQLite), `pipeline`, `rules`, `features`, `core`. Proposed libs: Riverpod, go_router, Drift, http/dio, url_launcher (decision log #25; confirm at Phase 3).
- Fetch on open, cached-first: render cached picks immediately; refresh sources in parallel (concurrency 4, 10 s timeout, 5 MB cap, conditional GET, 30 min TTL); isolate per-source failures; overall 15 s deadline; honor Retry-After.
- Daily picks: `stories_per_day` 5-10 (default 5), fixed for the local day, caps of 2 per source / 3 per topic.
- UI: calm, no infinite scroll or engagement nags; TalkBack labels, 200% text scale, contrast. Every story shows source, date, topic, 'why included' and links to the original publisher. Never show more than the stored excerpt.
- No backend, accounts, analytics or ads. Preferences, bookmarks and feedback stay on device.
- UI structure: `lib/app` (theme, go_router, providers), `lib/features/*` (today, explore, story, saved, settings), `lib/data/story_repository.dart`. Use the shared widgets (`StoryCard`, `EmptyState`, `ScrollableCenter`, `StatusBanner`) so states and accessibility stay consistent. Every list/empty state must scroll at 200% text on a 320 px screen.
- Today is cache-first (`TodayController`); create/extend picks only after a refresh; `todaysPicks()` is serialized.
- Test with `test/support/app_harness.dart` (in-memory DB, fake web, fake link/share). Use `ensureVisible` + a short pump before tapping off-screen widgets; load assets with `cache: false` for one-off reads.
- Checks: `flutter analyze && flutter test`. Never commit signing keys. Do not add CI until asked.

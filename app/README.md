# App (Flutter, Android first)

The shipped product. It fetches the curated feeds on the device when opened and does all processing locally. Architecture: [`../docs/architecture.md`](../docs/architecture.md). Plan: [`../docs/implementation-plan.md`](../docs/implementation-plan.md).

**Not yet created.** Phase 3 runs `flutter create --platforms=android .` here (code stays web-compatible; the web build is a future milestone) and adds:

```
lib/
  domain/        models
  data/sources/  StorySource, DirectRssStorySource (StaticJsonStorySource later)
  data/db/       Drift tables and migrations
  pipeline/      normalize, canonicalize, filters, dedupe, classify, rank, select (pure Dart)
  rules/         rules.json loader
  features/      today, explore, story, saved, preferences
  core/          http, clock, config
assets/rules/    bundled copy of ../rules/rules.json (scripts/sync-rules.sh)
test/fixtures/   fixture feeds and golden classification cases
```
Checks: `flutter analyze && flutter test`. Never commit signing keys.

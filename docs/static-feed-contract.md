# Static Feed Contract (web milestone)

**Status: implemented** (producer `app/tool/export_static.dart`, shared model `app/lib/web/static_feed.dart`, consumer `StaticJsonStorySource`). The export produces static files hosted on GitHub Pages, Netlify or similar, in the same folder as the web app. There is no API server.

## Files
```
/feed/v1/manifest.json
/feed/v1/sources.json
/feed/v1/articles/YYYY-MM-DD.json      # one file per publish day (UTC), newest 14 days kept
```
Only `manifest.json` is fetched fresh (`Cache-Control: no-cache`). Day files can change while the day is running, so the consumer requests them as `articles/YYYY-MM-DD.json?v=<generated_at ms>`, which busts any cache for each new export.

### manifest.json
```json
{"schema": 1, "generated_at": "2026-12-01T06:00:00Z", "rules_version": "2026.11.0",
 "articles": ["articles/2026-12-01.json", "articles/2026-11-30.json"], "count": 214}
```

### Article object (same fields as the on-device `articles` table)
```json
{"id": "a1b2c3d4e5f60718", "source_id": "positive-news", "canonical_url": "https://...",
 "title": "", "excerpt": "", "published_at": "2026-12-01T05:00:00Z", "language": "en",
 "regions": [], "topics": [], "story_types": [], "evidence_signals": [],
 "constructive_score": 0.82, "route": "today", "explanation": {"reason": "", "rules": []}, "rules_version": "2026.11.0"}
```
Never contains full article text. Excerpts are <= 300 characters.

## Rules
- Producer: `dart run tool/export_static.dart` in `app/`, which uses the exact fetch, parse, normalize and classify code of the Android app (so it cannot diverge from it). It exits non-zero and writes nothing if more than half the sources fail. Stories routed `excluded` are left out. Run on a schedule only when the owner asks (see `deployment.md`).
- Consumer: `StaticJsonStorySource` in the Flutter web build. It reads only the story fields and **re-classifies locally with the app's bundled rules**, so the exported `route`/`explanation` are informational. The app applies preferences, seen-tracking, diversity and daily selection locally, as on Android.
- A feed whose `schema` is not 1 is rejected; one broken entry or missing day file never hides the rest.
- Limitation: feeds only list recent items, so each export holds what the publishers currently list (up to 14 days). Carrying history over between runs is future work; the app keeps 30 days on the reader's own device/browser.
- Staleness: if `generated_at` is older than 48 h the UI shows a quiet "last updated" note.
- CORS: hosted on the same origin as the web app, so none is needed.
- The export includes only sources marked active in `source-allowlist.csv` and respects the same exclude rules.

# Static Feed Contract (future web milestone)

**Status: future.** Used only when the web app is built, after the Android milestone. The export job produces static files hosted on GitHub Pages, Netlify or similar. There is no API server.

## Files
```
/feed/v1/manifest.json
/feed/v1/sources.json
/feed/v1/articles/YYYY-MM-DD.json      # one file per publish day (UTC), newest 14 days kept
```
All files are immutable per version except `manifest.json`, which is fetched with `cache: no-cache` and lists the current articles files.

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
 "constructive_score": 0.82, "route": "today", "explanation": [], "rules_version": "2026.11.0"}
```
Never contains full article text. Excerpts are <= 300 characters.

## Rules
- Producer: the pipeline (reference implementation in `tools/pipeline-prototype`), run on a schedule.
- Consumer: `StaticJsonStorySource` in the Flutter web build. It trusts `route` and `explanation` when `rules_version` is known; the app still applies preferences, seen-tracking, diversity and daily selection locally.
- Staleness: if `generated_at` is older than 48 h the UI shows a quiet "last updated" note.
- CORS: hosted on the same origin as the web app, so none is needed.
- The export includes only sources marked active in `source-allowlist.csv` and respects the same exclude rules.

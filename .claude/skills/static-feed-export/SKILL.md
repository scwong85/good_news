---
name: static-feed-export
description: Future web milestone: export the pipeline output as static JSON for the Flutter web build and host it (GitHub Pages or Netlify).
---

# Static feed export (web milestone, started)

- Implemented: exporter `app/tool/export_static.dart`, model `app/lib/web/static_feed.dart`, consumer `app/lib/data/sources/static_json_story_source.dart`, build `scripts/build-web.sh`. Tests in `app/test/web/`.
- Contract: docs/static-feed-contract.md. Producer: the Dart exporter (same pipeline code as the app, same rules.json). Consumer: `StaticJsonStorySource` in the Flutter web build.
- Publishing and scheduling (GitHub Pages vs Netlify, cron) happen only when the owner asks; no CI workflow before then. Verify current free-tier limits first.
- Flutter web build for a project site: `--base-href /<repo>/`, hash URLs, `404.html` copy of index.html.

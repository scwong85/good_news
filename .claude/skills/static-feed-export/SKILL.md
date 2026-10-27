---
name: static-feed-export
description: Future web milestone: export the pipeline output as static JSON for the Flutter web build and host it (GitHub Pages or Netlify).
---

# Static feed export (future)

- Do not start until Phases 2-6 are done and the owner starts the web milestone.
- Contract: docs/static-feed-contract.md. Producer: an `export_static` command in tools/pipeline-prototype using the same rules.json. Consumer: `StaticJsonStorySource` in the Flutter web build.
- Hosting/scheduling decisions (GitHub Pages vs Netlify, cron) are made then; no CI workflow before the owner asks. Verify current free-tier limits first.
- Flutter web build for a project site: `--base-href /<repo>/`, hash URLs, `404.html` copy of index.html.

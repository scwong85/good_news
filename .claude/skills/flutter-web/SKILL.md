---
name: flutter-web
description: Flutter app for Good News covering the shared Android + web codebase, and the static web build hosted on GitHub Pages. Use for any app UI work.
---

# Flutter app (Android + web)

- One codebase in `app/`; platforms: android, web (ios later). API per docs/api-contracts.md; API base URL via `--dart-define=API_BASE_URL`.
- Screens: Today, Explore (topic/region/type filters + search), Story detail (source attribution, original link, "why this story was included", save/share), Saved (offline-friendly), Preferences.
- State: Riverpod; routing: go_router with **hash URL strategy** (GitHub Pages has no SPA fallback). Storage: shared_preferences/drift for anonymous id, bookmarks, cached saved articles.
- GitHub Pages: build with `--base-href /<repo>/` (project site) and `--release`; prefer the CanvasKit/WASM renderer only if size is acceptable, else HTML-friendly layouts; keep a `404.html` copy of `index.html`. Pages serves static files only, so the Django API must be hosted elsewhere with CORS allowing the Pages origin.
- Web caveats to design for: weaker SEO and larger first load than a server-rendered site. Keep the initial feed under 2 s: lazy-load, small assets, cache `today` response.
- Calm design, accessible (semantics, contrast, text scaling), responsive for phone/tablet/desktop. No account needed; every story links to the original publisher.
- Android: opt-in push, offline reading of saved articles, share extension, home-screen widget (Phase 8).
- Do not add CI/deploy workflows until the owner asks.

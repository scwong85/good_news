# Release and Deployment

## Milestone 1: Android app
- Build: `flutter build appbundle --release`. Release signing keystore and `key.properties` are never committed (see `.gitignore`).
- Signing (not applied yet): create an upload keystore outside the repo, put its details in `android/key.properties` (git-ignored: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`), and read them in `android/app/build.gradle` to define `signingConfigs.release`. Use Play App Signing. Full steps are in `release-checklist.md`.
- Build with the contact address: `flutter build appbundle --release --dart-define=CONTACT_EMAIL=you@example.org`.
- Distribution: Google Play (internal testing track first), plus APK for sideload testing.
- Required for the store: a **privacy policy URL** and a data-safety form (declare no data collected). The policy page needs static hosting, so a minimal GitHub Pages site (or a repository-hosted page) is part of the release step. Include a contact address for takedown/removal requests (open item).
- No servers, databases, schedulers or secrets are needed.
- Release checks (`before_release`): tests, `flutter analyze`, rules sync check, parity test, manual QA. Post-release (`after_release`): smoke test on a clean device.
- CI/CD is intentionally not set up yet.

## Milestone A: Web build (built; publishing not done)
- `scripts/build-web.sh [--base-href /good_news/]` runs the exporter (live feeds) and `flutter build web --release --no-web-resources-cdn` (fonts and CanvasKit are bundled: no Google CDN requests), then assembles `app/build/site` with `feed/v1/`, a `404.html` copy of `index.html` and `.nojekyll`. Verified in headless Chromium: only same-origin requests.
- `web/sqlite3.wasm` (sqlite3 3.8.0 release) and `web/drift_worker.js` (compiled from `web/drift_worker.dart` with `dart compile js -O4`) are committed; rebuild both when upgrading `drift`/`sqlite3`.
- Host options: GitHub Pages (project site: build with `--base-href /good_news/`, hash URLs, `404.html` copy of `index.html`) or Netlify (static hosting; verify current free limits and whether a Python build step is available before relying on it).
- **Published by `.github/workflows/pages.yml`** (added at the owner's request): on every push to `main`, daily at 05:17 UTC and on demand it runs analyze and tests, then `scripts/build-web.sh --base-href /<repo>/`, then deploys `app/build/site` to GitHub Pages. One-time repository setting: Settings > Pages > Source = "GitHub Actions". Optional repository variable `CONTACT_EMAIL` (Settings > Variables) feeds the privacy page. The site lives at `https://<owner>.github.io/<repo>/`. A failed export (more than half the sources down) fails the run and leaves the previous site online.
- Build with `CONTACT_EMAIL=you@example.org scripts/build-web.sh` so the policy page shows the contact address.
- Pages is static only: no API, and CORS is not needed because the data is same-origin.

## Future milestone B and beyond
Remote rules hosting, optional server (push, accounts, sync) and iOS are out of scope until the client-side product is proven.

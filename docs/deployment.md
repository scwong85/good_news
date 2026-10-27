# Release and Deployment

## Milestone 1: Android app
- Build: `flutter build appbundle --release`. Release signing keystore and `key.properties` are never committed (see `.gitignore`).
- Distribution: Google Play (internal testing track first), plus APK for sideload testing.
- Required for the store: a **privacy policy URL** and a data-safety form (declare no data collected). The policy page needs static hosting, so a minimal GitHub Pages site (or a repository-hosted page) is part of the release step. Include a contact address for takedown/removal requests (open item).
- No servers, databases, schedulers or secrets are needed.
- Release checks (`before_release`): tests, `flutter analyze`, rules sync check, parity test, manual QA. Post-release (`after_release`): smoke test on a clean device.
- CI/CD is intentionally not set up yet.

## Future milestone A: Web hosting
- Export job (Python reference pipeline) on a schedule writes the static feed (`static-feed-contract.md`).
- Host options: GitHub Pages (project site: build with `--base-href /good_news/`, hash URLs, `404.html` copy of `index.html`) or Netlify (static hosting; verify current free limits and whether a Python build step is available before relying on it).
- A scheduler is required for fresh data (for example a GitHub Actions cron). Add it only when the owner asks.
- Pages is static only: no API, and CORS is not needed because the data is same-origin.

## Future milestone B and beyond
Remote rules hosting, optional server (push, accounts, sync) and iOS are out of scope until the client-side product is proven.

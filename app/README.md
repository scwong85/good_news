# App (Flutter: Android + Web)

Single Flutter codebase for the Android app and the web app. Web is deployed to GitHub Pages; the API is hosted separately (see `../docs/deployment.md`).

Not yet implemented. Phase 4 creates the project (`flutter create --platforms=android,web,ios .`) and builds Today, Explore, Story detail, Saved and Preferences.

Web build for a GitHub project site:
```
flutter build web --release --base-href /good_news/ --dart-define=API_BASE_URL=https://<api-host>/api/v1
```
Use hash URL strategy (Pages has no SPA fallback). Details: `../.claude/skills/flutter-web/SKILL.md`.

#!/usr/bin/env bash
# Build the static web site into app/build/site: the Flutter web build plus a fresh static feed.
#   scripts/build-web.sh [--base-href /good_news/] [--skip-export]
# Hosting (GitHub Pages/Netlify) is a separate, owner-approved step: see docs/deployment.md.
set -eu
root="$(cd "$(dirname "$0")/.." && pwd)"
base="/good_news/"; export_feed=1
while [ $# -gt 0 ]; do
  case "$1" in
    --base-href) base="$2"; shift 2 ;;
    --skip-export) export_feed=0; shift ;;
    *) echo "unknown option $1"; exit 2 ;;
  esac
done
flutter_bin="$(command -v flutter || echo /opt/flutter/bin/flutter)"
dart_bin="$(command -v dart || echo /opt/flutter/bin/dart)"
cd "$root/app"
[ "$export_feed" = 1 ] && "$dart_bin" run tool/export_static.dart --out build/feed/v1
[ -f build/feed/v1/manifest.json ] || { echo "no feed in app/build/feed/v1 (run without --skip-export)"; exit 1; }
"$flutter_bin" build web --release --base-href "$base" --no-web-resources-cdn \
  --dart-define=CONTACT_EMAIL="${CONTACT_EMAIL:-}"
rm -rf build/site && cp -r build/web build/site && mkdir -p build/site/feed && cp -r build/feed/v1 build/site/feed/v1
cp build/site/index.html build/site/404.html   # GitHub Pages: unknown paths load the app
touch build/site/.nojekyll
echo "site ready in app/build/site (base href $base)"

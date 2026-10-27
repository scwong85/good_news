#!/usr/bin/env bash
# Copy rules/rules.json into the app's assets. Use --check to fail if they differ.
set -eu
root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/rules/rules.json"
dst="$root/app/assets/rules/rules.json"
if [ ! -f "$src" ]; then echo "rules/rules.json not created yet (Phase 2)"; exit 0; fi
if [ "${1:-}" = "--check" ]; then [ -d "$root/app/assets" ] || { echo "app/assets not created yet (Phase 3): skipping rules sync check"; exit 0; }; cmp -s "$src" "$dst" || { echo "rules out of sync: run scripts/sync-rules.sh"; exit 1; }; exit 0; fi
mkdir -p "$(dirname "$dst")" && cp "$src" "$dst" && echo "synced"

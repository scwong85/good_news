#!/usr/bin/env bash
# Copy docs/legal/privacy-policy.md into the app's assets. Use --check to fail if they differ.
set -eu
root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/docs/legal/privacy-policy.md"
dst="$root/app/assets/legal/privacy_policy.md"
if [ "${1:-}" = "--check" ]; then
  [ -d "$root/app/assets" ] || exit 0
  cmp -s "$src" "$dst" || { echo "privacy policy out of sync: run scripts/sync-legal.sh"; exit 1; }
  exit 0
fi
mkdir -p "$(dirname "$dst")" && cp "$src" "$dst" && echo "synced"

#!/usr/bin/env bash
# Dev-workflow check used by the Claude Code Stop hook (.claude/settings.json).
# Runs checks for whichever parts of the repo exist. Exits 2 (block) on failure.
#   - rules sync check
#   - Flutter app: analyze + test (when app/pubspec.yaml and flutter exist)
#   - Python reference pipeline: only when DEV_CHECK_PROTOTYPE=1 (needs Postgres)
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
status=0

"$root/scripts/sync-rules.sh" --check || status=2

if [ -f "$root/app/pubspec.yaml" ] && command -v flutter >/dev/null 2>&1; then
  (cd "$root/app" && flutter analyze && flutter test) || status=2
fi
if [ "${DEV_CHECK_PROTOTYPE:-0}" = "1" ] && command -v uv >/dev/null 2>&1; then
  (cd "$root/tools/pipeline-prototype" && uv run ruff check . && uv run pytest -q) || status=2
fi
exit $status

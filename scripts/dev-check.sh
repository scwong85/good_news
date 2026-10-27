#!/usr/bin/env bash
# Dev-workflow check used by the Claude Code Stop hook (.claude/settings.json).
# Runs checks for whichever parts of the repo exist. Exits 2 (block) on failure.
#   - rules / sources asset sync checks and the golden URL fixture check
#   - Flutter app: analyze + test (when app/pubspec.yaml and flutter exist)
#   - Python reference pipeline: only when DEV_CHECK_PROTOTYPE=1 (needs Postgres)
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
status=0

"$root/scripts/sync-rules.sh" --check || status=2
python3 "$root/scripts/sync-sources.py" --check || status=2
python3 "$root/scripts/export-url-golden.py" --check || status=2

flutter_bin="$(command -v flutter || true)"
[ -z "$flutter_bin" ] && [ -x /opt/flutter/bin/flutter ] && flutter_bin=/opt/flutter/bin/flutter
if [ -f "$root/app/pubspec.yaml" ] && [ -n "$flutter_bin" ]; then
  (cd "$root/app" && "$flutter_bin" analyze && "$flutter_bin" test -r failures-only) || status=2
fi
if [ "${DEV_CHECK_PROTOTYPE:-0}" = "1" ] && command -v uv >/dev/null 2>&1; then
  (cd "$root/tools/pipeline-prototype" && uv run ruff check . && uv run pytest -q) || status=2
fi
exit $status

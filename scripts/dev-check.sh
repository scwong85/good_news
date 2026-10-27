#!/usr/bin/env bash
# Dev-workflow check used by the Claude Code Stop hook (.claude/settings.json).
# Runs lint/tests for whichever parts of the repo exist. Exits 2 (block) on failure.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
status=0

if [ -f "$root/backend/manage.py" ] && command -v uv >/dev/null 2>&1; then
  (cd "$root/backend" && uv run ruff check . && uv run pytest -q) || status=2
fi
if [ -f "$root/app/pubspec.yaml" ] && command -v flutter >/dev/null 2>&1; then
  (cd "$root/app" && flutter analyze && flutter test) || status=2
fi
exit $status

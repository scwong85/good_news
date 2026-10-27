---
name: pipeline-prototype
description: Work on the Python/Django reference pipeline in tools/pipeline-prototype (rules evaluation, feed behaviour reference, future static export).
---

# Pipeline prototype (reference)

- Not shipped or deployed. Used to develop/evaluate rules quickly, as a behavioural reference for the Dart port, and for the future static web export.
- Layout and commands: tools/pipeline-prototype/README.md. Checks: `uv run ruff check . && uv run pytest` (needs Postgres; default postgres://goodnews:goodnews@localhost:5432/goodnews).
- Original server data model: tools/pipeline-prototype/DATA_MODEL.md. Do not grow it into a product backend unless the owner changes the architecture (decision log #19).

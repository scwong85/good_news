# Good News Aggregator

A calm Android app (web later) that gives you 5 to 10 credible, constructive news stories a day from vetted sources. The app fetches the feeds itself when you open it and does all filtering and classification on your device. There is no server, account or tracking.

- Product, architecture and plan: [`docs/`](docs/) (start with [`product-brief.md`](docs/product-brief.md), [`architecture.md`](docs/architecture.md), [`implementation-plan.md`](docs/implementation-plan.md))
- Contributor/agent guide: [`CLAUDE.md`](CLAUDE.md)
- Status: Phases 0 to 2 done (editorial foundation, Python reference pipeline, shared classification rules; Phase 2 met on revised targets, see [`docs/evaluation-report.md`](docs/evaluation-report.md)). Phases 3 and 4 (Flutter ingestion, on-device classification, de-duplication and daily picks) are done in code but not yet run on a device. The Android UI (Phase 5) is also done in code. Phase 6 (Android hardening: hide/report, privacy policy, policy tests) is done in code. **Next: a first run on a real device, then Phase 7 (UI overhaul so the app feels like good news, see [`docs/ui-overhaul.md`](docs/ui-overhaul.md)) and Phase 8 (release).** The web build (milestone A: exporter, static feed, `scripts/build-web.sh`) is built and verified locally but not published. See [`docs/decision-log.md`](docs/decision-log.md).

## Layout
```
app/                       Flutter app (Android first): ingestion foundation, harness screen
rules/                     Classification rules, golden cases, baseline metrics
docs/                      Product, architecture, policy, plan, decisions
data/                      Labeled seed data
tools/pipeline-prototype/  Python/Django reference pipeline (not deployed)
scripts/                   Dev tooling
.claude/                   Project skills and dev hooks
```

## Reference pipeline (optional)
```
cd tools/pipeline-prototype
docker compose up -d db
uv sync && uv run pytest
```

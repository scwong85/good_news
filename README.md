# Good News Aggregator

A calm Android app (web later) that gives you 5 to 10 credible, constructive news stories a day from vetted sources. The app fetches the feeds itself when you open it and does all filtering and classification on your device. There is no server, account or tracking.

- Product, architecture and plan: [`docs/`](docs/) (start with [`product-brief.md`](docs/product-brief.md), [`architecture.md`](docs/architecture.md), [`implementation-plan.md`](docs/implementation-plan.md))
- Contributor/agent guide: [`CLAUDE.md`](CLAUDE.md)
- Status: Phase 0 (editorial foundation) mostly done; Phase 1 (Python reference pipeline) done; **next: Phase 2, shared classification rules.** Web hosting is a future milestone. See [`docs/decision-log.md`](docs/decision-log.md).

## Layout
```
app/                       Flutter app (Android first). Created in Phase 3
rules/                     Classification rules (rules.json from Phase 2)
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

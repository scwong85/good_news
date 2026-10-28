# Good News Aggregator: project guide

Calm, trustworthy app that gives a small daily briefing (5-10 stories, user setting) of credible *constructive* news. Read `docs/product-brief.md`, then `docs/architecture.md` and `docs/implementation-plan.md`.

## Architecture in one paragraph
**Client-side first.** A Flutter app (Android first, in `app/`) fetches the curated RSS feeds itself when opened, then parses, filters, classifies (rules in `rules/rules.json`), de-duplicates and selects the day's picks on the device, stored in SQLite. There is no server we operate and no background fetching. The **web build (milestone A, started)** is the same Flutter app reading pre-built static JSON (`docs/static-feed-contract.md`), because browsers block direct feed reads; a Dart exporter (`app/tool/export_static.dart`) produces it. `tools/pipeline-prototype/` is the Python/Django reference pipeline (Phase 1, done): used for rules evaluation and the future web export, not deployed.

## Shared context (keep these current)
`docs/`: product-brief, architecture, implementation-plan, evaluation-report, editorial-policy, source-allowlist.csv, classification-rules, data-model (on-device), static-feed-contract (future), pipeline-hooks, test-plan, deployment, decision-log. Data: `data/seed_labels.jsonl` (draft labels, human review pending). Rules: `rules/` (`rules.json`, `golden_cases.jsonl`, `baseline_metrics.json`); evaluation: `docs/evaluation-report.md`.

## Non-negotiables
- Curated allowlist only. No broad discovery, no Tier 3.
- Never republish full articles: headline + feed excerpt (<= 300 chars) + source + link to the original. Never fetch article pages.
- Every classification has an explanation; rules are deterministic and versioned; change them only with an evaluation on the labeled set.
- Classifier parity: the Python reference and the Dart port must agree on `rules/golden_cases.jsonl` (all labeled articles + edge cases). Regex semantics are ASCII in both.
- Fetch-on-open only; no background sync. Be a polite client: User-Agent, cache TTL 30 min, conditional GET, honor 429/Retry-After.
- Privacy: no accounts, analytics or ads; data stays on the device; telemetry only if opt-in.
- No LLM dependency.
- The web app is published to GitHub Pages by the one workflow the owner asked for (`.github/workflows/pages.yml`: daily export + deploy). Don't add other CI workflows, servers or schedulers until the owner asks. No server we operate, ever, without the owner.
- Roadmap after Phase 5: Phase 6 hardening (done in code), Phase 7 UI overhaul (`docs/ui-overhaul.md`, built; owner sign-off pending), Phase 8 release (`docs/release-checklist.md`).

## Workflow
- Follow the phase order in `docs/implementation-plan.md`; update the tracker, decisions and open questions in `docs/decision-log.md`.
- Skills in `.claude/skills/` cover each area (`flutter-app`, `rss-ingestion`, `rule-based-classification`, `deduplication`, `privacy-and-content-licensing`, `evaluation-and-test-writing`, `pipeline-prototype`; `static-feed-export`, `local-embeddings`, `llm-enrichment` are future).
- A Stop hook runs `scripts/dev-check.sh` (rules and legal-asset sync checks, `flutter analyze/test` once `app/` exists; set `DEV_CHECK_PROTOTYPE=1` to include the Python prototype, which needs Postgres).
- Commands (Flutter is at `/opt/flutter/bin`): app `cd app && flutter analyze && flutter test`; prototype `cd tools/pipeline-prototype && uv run pytest`; rules sync `scripts/sync-rules.sh`.
- Tests never hit the live network; use fixture feeds.

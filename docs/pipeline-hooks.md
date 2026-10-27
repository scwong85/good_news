# Pipeline Hooks (application-level contracts)

These are hooks in the Django/Celery pipeline, implemented in code (not Claude Code hooks).

| Hook | Runs | Checks / actions |
|---|---|---|
| `before_ingestion` | Before each source fetch | Source active; licensing note present; robots policy respected; within rate limit / fetch interval |
| `after_ingestion` | After a successful run | Normalize -> deduplicate -> classify (async chain) |
| `before_publish` | Before status -> `published` | Status `approved`; source trust >= threshold; no unresolved flags; Tier 3 reviewed by a human; LLM drafts reviewed |
| `after_user_feedback` | After feedback saved | Update aggregates; queue flagged articles (`not_credible` threshold) |
| `before_llm_call` | Before any LLM request | Enrichment enabled; budget remaining; cache miss; provider healthy; prompt version recorded |
| `after_llm_call` | After response | Validate JSON schema; store as draft; force review on low confidence; never publish |
| `before_deploy` | CI/CD (later) | Tests, migrations, lint, security checks, smoke tests |
| `after_deploy` | CI/CD (later) | Health checks; ingestion and feed endpoint verified |

Dev-workflow hooks for Claude Code live in `.claude/settings.json` and `scripts/dev-check.sh`.

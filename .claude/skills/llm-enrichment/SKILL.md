---
name: llm-enrichment
description: (FUTURE, not in the current plan) Optional LLM enrichment (summaries, why-it-matters) with budget, caching, schema validation and mandatory review. Disabled by default.
---

# LLM enrichment (future, optional)

Not in the current plan (no server). Only consider with the web export or a future backend; drafts only, human-reviewed.

- Disabled by default (`LLM_ENRICHMENT_ENABLED=0`). The product must work fully without it.
- Provider abstraction + disable switch + fallback. Run `before_llm_call` (budget, cache, health, prompt version) and `after_llm_call` (JSON-schema validation, store as draft) hooks.
- Output is a draft only: neutral 1-2 sentence summary, why it matters, topic/region suggestions, evidence signals, confidence. It NEVER auto-publishes and always routes to human review.
- Send only title, excerpt and metadata; never present output as independent verification.
- Cache by (article, prompt_version, model); enforce a daily cost cap and log cost per accepted story.
- If using the Claude API, load the `claude-api` skill first.

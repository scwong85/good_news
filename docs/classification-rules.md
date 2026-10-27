# Classification Rules

Deterministic and transparent. The reference implementation (Python, `tools/pipeline-prototype/classifier/`) and the app (Dart, Phase 4) must give identical results from `rules/rules.json`. Parity is tested with `rules/golden_cases.jsonl`. Measured accuracy: `evaluation-report.md`.

Input available on device: title, feed excerpt (<= 300 chars), source (trust score, tier), URL, publish date, language. **No article body.**

## Pipeline
1. **Stage 1: hard filters** (result `excluded`, reason recorded): non-HTTP(S) URL; empty title; missing publish date; older than `age_window_days` (14, only when a current time is supplied); language not in `language_allowlist`; blocked domain; global excludes (weekly roundups, "Good News in History", podcast transcripts, photo galleries, newsletter/reading lists, magazine promos, sponsored URLs); per-source excludes.
2. **Stage 2: score** = `base_score` (0.30) + capped group totals + source prior. Each `score_rules` entry has `id`, `group` (`positive`, `negative`, `evidence`), `field` (`title|excerpt|text|url`), `regex`, `flags` (`i` default), `weight`, optional `signal` (an evidence signal name) and `veto`. Each rule counts at most once. Group totals are capped (`positive` +0.40, `negative` -0.60, `evidence` +0.25). Source prior = `(trust - 0.5) * 0.2`. The result is clamped to [0, 1] and rounded to 6 places. Every matched rule is recorded in the explanation (`rule`, `group`, `weight`, `match`).
3. **Stage 3: tags**: `topics` and `story_types` from keyword tables (highest match count first, ties by rules-file order; max 3 topics, max 2 story types; `human_interest` default for a shown story with no type). `evidence_signals` come from rules that carry a `signal`. Story types are advisory (weak accuracy, see the report).
4. **Stage 4: route** (no human in the loop):

| Route | Condition | Used for |
|---|---|---|
| `today` | score >= 0.50, and no `veto` rule matched, and at least 1 `positive` rule matched, and (>= 1 evidence signal or source trust >= 0.90) | Preferred pool for the daily picks |
| `explore` | score >= 0.42 and not `today` (reason `no_evidence`, `no_vocabulary` or `veto` when the score alone would have qualified) | Explore; **fills the daily picks when `today` has too few stories** |
| `excluded` | Stage 1 filter, or score < 0.42 (`low_score`) | Not shown |

### Daily-pick fill rule
With about 2.6 `today` stories per day on average, the selector takes `today` stories first (ranked), then the best `explore` stories by score (floor 0.42) until it has `stories_per_day`. The story detail screen states why a story was included.

## Portability rules for `rules.json` (so Dart matches Python)
Patterns use only syntax common to Python `re` and Dart `RegExp`: no inline flags, no named groups, no possessive quantifiers; case-insensitivity comes from `flags`. Matching is `search` (anywhere); the first match is recorded. Weights are summed in file order. Topic and story-type keyword tables are always case-insensitive.

## Changing rules
1. Edit `rules/rules.json` (bump `rules_version`).
2. `python -m classifier.evaluate --split tune` (never tune on `test2`).
3. `python -m classifier.evaluate --write-baseline` and `python -m classifier.export_golden` and commit all.
4. When the app exists: `scripts/sync-rules.sh`.
The regression test fails if metrics drop below the baseline or the golden file is stale.

## Known limits
Rules can't verify facts; `policy_violation` detection is blocklist-based only. Excerpt-only input makes evidence signals sparse, so `today` is intentionally strict and recall is modest (about 27%).

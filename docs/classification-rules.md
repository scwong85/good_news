# Classification Rules

Deterministic and transparent. The reference implementation (Python, `tools/pipeline-prototype`) and the app (Dart) must give the same result from the same `rules/rules.json`. Parity is tested (`test-plan.md`).

Input available on device: title, feed excerpt (<= 300 chars), feed categories, source metadata, publish date. **No article body.**

## Stage 1: Hard filters (result: `excluded`, with reason)
Non-HTTP(S) URL; missing title, URL or publish date; older than the age window (default 14 days); unsupported language; blocklisted domain; sponsored/promo URL patterns (`/sponsored/`, `/partner-content/`, `/advertorial/`); per-source exclude patterns (title/URL regex, for example weekly roundups, "Good News in History", podcast transcripts, photo galleries); user-hidden items.

## Stage 2: Constructive score (0-1)
Sum of weighted features, clamped to [0, 1], each recorded in the explanation (feature, weight, matched text).
- **Positive:** lexicon terms (breakthrough, recovery, restored, reduced, expanded, protected, approved, launched, partnership, volunteers, solution, progress...); named institutions (university, hospital, NGO, agency); numbers, percentages and study references; constructive-category tags in the feed.
- **Negative:** conflict/harm lexicon (attack, war, killed, crisis, scandal, fraud, lawsuit, collapse...); clickbait and promotional patterns; excessive punctuation; listicle/how-to patterns; opinion markers.
- **Source prior:** small adjustment from `trust_score` and tier.

## Stage 3: Topics, regions, story types, evidence signals
Keyword/lexicon maps to `topics`, `regions` (source default plus place-name lexicon), `story_types` and `evidence_signals` (see `editorial-policy.md`). First matching rules win; all matches are explained.

## Stage 4: Routing (no human in the loop)
| Route | Condition (initial values, calibrated in Phase 2) | Where it appears |
|---|---|---|
| `today` | score >= `today_threshold` (0.70) and (>= 1 evidence signal or source trust >= 0.90) and no negative veto | Eligible for the daily 5-10 picks and Explore |
| `explore` | `explore_threshold` (0.45) <= score < `today_threshold`, or `today` conditions missing evidence | Explore only |
| `excluded` | score < `explore_threshold` or Stage 1 filter | Not shown |
Thresholds are tuned on the dev labels to meet the precision target and verified on the held-out set. `human_interest` stories are never above `explore` priority unless score is high.

## `rules.json` (schema sketch)
```json
{
  "rules_version": "2026.11.0",
  "language_allowlist": ["en"],
  "age_window_days": 14,
  "thresholds": {"today": 0.70, "explore": 0.45},
  "stage1": {"blocked_domains": [], "blocked_url_patterns": [], "source_excludes": {"Good Good Good": [{"field": "title", "regex": "^Good News This Week"}]}},
  "lexicons": {"positive": {"breakthrough": 0.12}, "negative": {"attack": -0.25}},
  "patterns": [{"id": "listicle", "field": "title", "regex": "^\\d+ ", "weight": -0.2}],
  "topics": {"environment": ["wildlife", "reef"]},
  "story_types": {"solution": ["solution", "works", "pilot"]},
  "evidence": {"data_cited": ["\\d+%"], "named_institution": ["University", "Institute"]}
}
```
Canonical file: `rules/rules.json`; `scripts/sync-rules.sh` copies it to `app/assets/rules/` and fails if they differ.

## Evaluation
Labeled set `data/seed_labels.jsonl` (draft labels, human review pending) is split into dev and held-out test. Report precision/recall/F1 per story type, route accuracy and false-positive rate for `today`. Targets: `today` precision >= 85%, Tier-1 route accuracy >= 80%.

## Known limits
Rules can't verify facts, and `policy_violation` detection is only blocklist-based. Excerpt-only input makes evidence signals sparse, so `today` is intentionally strict.

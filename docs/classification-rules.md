# Classification Rules

Rules version is stored with each audit row. Weights live in `backend/classification/scoring.yaml` (created in Phase 2).

## Stage 1: Deterministic filters (hard rejects -> `filtered_out`)
Non-HTTP(S) URL; duplicate canonical URL; older than `ARTICLE_MAX_AGE_DAYS` (14); unsupported language; blacklisted domain; sponsored/promo URL patterns (`/sponsored/`, `/partner-content/`, `/advertorial/`); missing title, URL or publish date; source include/exclude rules.

## Stage 2: Constructive score (0-1, transparent)
**Positive:** breakthrough, recovery, restored, reduced, expanded, protected, approved, launched, developed, partnership, volunteers, solution, progress; named institutions (university, hospital, NGO, agency); numbers/percentages/dates/study references; topical categories.
**Negative:** attack, war, killed, crisis, scandal, fraud, lawsuit, collapse; clickbait patterns; excess exclamation marks or promo language; missing author/date/attribution.

Every contribution is recorded in `classification_explanation` (feature, weight, matched text).

## Routing (the score is never a final decision on its own)
| Condition | Route |
|---|---|
| score >= 0.75 and source trust high and not in a forced-review case | auto-publish (after `before_publish` checks) |
| 0.45 <= score < 0.75 | `pending_review` |
| score < 0.45 | archive/reject (`not_constructive`) |
Forced review overrides: Tier 3, new source (<100 articles reviewed), user-flagged, LLM-enriched.

## Topic and region rules
Keyword/lexicon maps -> `topics`; source default regions + place-name lexicon -> `regions`. Maps in versioned config.

## Deduplication (Phase 3)
Canonical URL -> normalized-title similarity -> local embedding cosine >= 0.90. Keep the highest-quality article as primary; link alternates.

## Evaluation
Hold out the labeled set (`data/seed_labels.jsonl`); report precision/recall/F1 per story type; target >= 80% correct routing on Tier 1.

# Editorial Policy

## Definition
A story is **constructive news** if it reports credible progress, solutions, recovery, cooperation, scientific advancement, community action, or measurable improvement.

A story does **not** qualify merely because it is uplifting, cute, sponsored, political, or optimistic.

## Story types (`story_types`)
| Code | Definition | Qualifies when | Does not qualify |
|---|---|---|---|
| `progress` | Measurable improvement, recovery, reform, breakthrough | A named metric/outcome improved | Vague "things are getting better" |
| `solution` | A working approach to a social, environmental, technical or institutional problem | Approach is described with evidence of results | A proposal with no results |
| `community` | Cooperation, volunteering, mutual aid, local action | Concrete action by identifiable people/groups | Generic feel-good anecdote |
| `science_health` | Validated research, medical progress, discovery, public-health improvement | Peer-reviewed or institution-backed | Single preliminary/unreplicated claim framed as cure |
| `environment` | Conservation, restoration, clean energy, biodiversity, pollution reduction | Quantified or institution-confirmed | Corporate greenwashing |
| `education_opportunity` | Access to education, skills, employment, inclusion | Program with reach/outcomes | Pure fundraising appeal |
| `human_interest` | Resilience, kindness, achievement (**lower priority**) | Meaningful reader value | Cute-animal/viral content |
| `technology_for_good` | Beneficial applications of technology | Real deployment or evidence | Product launch/PR |

## Rejection reasons (`rejection_reason`)
| Code | Meaning |
|---|---|
| `not_constructive` | Negative, neutral, or primarily conflict-focused |
| `too_trivial` | No meaningful reader value |
| `promotional` | Advertisement, sponsored content, self-promotion |
| `unverified` | No credible evidence, named sources, institutions or data |
| `duplicate` | Substantially the same story already present |
| `paywalled_or_unusable` | Cannot legally/practically present a useful summary or link |
| `policy_violation` | Hate, harassment, medical misinformation, unsafe content |

## Evidence signals (`evidence_signals`)
`named_institution`, `data_cited`, `study_referenced`, `named_expert`, `official_source`, `measurable_outcome`, `independent_confirmation`.
High-priority publication (Today feed) requires at least one.

## Source trust
- `trust_score` 0-1, set per source. Tier 1 starts at 0.85-0.95, Tier 2 at 0.70-0.90, Tier 3 is always review-only.
- New sources: first 100 articles go through human review.

## Review queue (launch rules)
Review is required for: all Tier 3 articles; low/ambiguous scores; first 100 articles from any new source; user-flagged articles; LLM-enriched articles.

## Corrections & takedown
Publishers or readers can request removal via the contact address (to be set in `docs/deployment.md`). Flagged articles leave the feed immediately pending review. Status history is preserved. AI output is never presented as independent verification.

## Copyright
Show headline, short permitted excerpt or neutral summary, source name and canonical link only. Respect RSS terms and robots directives. Keep a per-source licensing note in `source-allowlist.csv`.

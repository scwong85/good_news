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
Today requires at least one evidence signal, or a source with `trust_score` >= 0.90 (see `classification-rules.md`).

## Source trust
- `trust_score` 0-1, set per source in `source-allowlist.csv`. Tier 1 starts at 0.85-0.95, Tier 2 at 0.70-0.90. **Tier 3 (broad discovery) is out of scope** for the client-side app.
- A new source is added only after at least 50 of its items are labeled and the rules are evaluated on them. Sources that yield few constructive items (for example Upworthy, YES! Magazine in the first sample) get low trust or are disabled by default.

## Curation without runtime review
There is no human review queue in the app. Instead:
- Only allowlisted sources are fetched.
- Stories reach **Today** only when the versioned rules say so (score threshold plus an evidence signal or a highly trusted source). Borderline stories appear only in **Explore**.
- Rules and sources change only through maintainers' releases, after evaluation on the labeled set (`classification-rules.md`).
- A reader can report a story ("not credible", "not for me"); it is hidden on that device. Maintainers review reports offline when they are shared (for example through store feedback) and adjust rules.
- Maintainers sample live picks regularly and record corrections as new labels.
Human review (reviewed-list file or PR workflow) returns as a future milestone together with the web export.

## Corrections and takedown
Publishers and readers can request removal through the contact address in the privacy policy and store listing (to be set). A removal request is handled by disabling the source or adding a blocklist rule in the next release (immediately via remote rules once that milestone exists). AI output, if ever added, is never presented as independent verification.

## Copyright
Show headline, the short feed excerpt (<= 300 characters), source name and canonical link only. The app never fetches article pages. Use only the feeds the publishers provide, identify the app with a clear User-Agent, cache aggressively (30 min TTL) and honor `429`/`Retry-After`. Keep a per-source licensing note in `source-allowlist.csv`; per-source terms review is still pending.

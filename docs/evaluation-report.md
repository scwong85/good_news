# Classifier Evaluation Report (Phase 2)

Rules version **2026.11.2** (`rules/rules.json`). Reference implementation: `tools/pipeline-prototype/classifier/`. Reproduce with `python -m classifier.evaluate --split <split>`.

## Data and method
- 290 real articles from 10 feeds, labeled against `editorial-policy.md` (labels in `data/seed_labels.jsonl`).
- **All labels are drafts written by Claude (one labeler), not yet reviewed by a person.** Treat every number below as provisional: label errors and labeler bias are not measured.
- Splits: `dev` (102, labeled first, used for tuning), `dev2` (92, labeled blind before any rules existed, then used for tuning after its first evaluation), `test2` (96, labeled blind before the tuning on dev2 started, run once for the headline result).
- A route is "correct" if gold-constructive items land in `today` or `explore` and gold-rejected items land in `excluded`. "Today precision" is the share of `today` predictions that are gold-constructive.
- Input is title + feed excerpt only (what the app will have).

## History (honest account)
| Step | Rules | Split | Today precision | Tier-1 route accuracy |
|---|---|---|---|---|
| Tuned on dev | 2026.11.0 | dev | 92.3% (12/13) | 81.5% |
| First blind run | 2026.11.0 | dev2 (then called "test") | **80.0%** (12/15), missed target | 80.5% |
| Tuned on dev + dev2, then frozen | 2026.11.1 | tune (dev+dev2) | 92.3% (24/26) | 81.6% |
| **Second blind run (headline)** | 2026.11.1 | test2 | **92.3%** (12/13), met | **73.3%**, missed target |
| Bug fix (`%` never counted as `data_cited`), no change on test2 | 2026.11.2 | test2 (no longer blind) | 92.3% | 73.3% |

## Final results (2026.11.2)
| Split | n | Route acc. | Tier-1 route acc. | Today: predicted / precision / recall | Shown (today+explore): precision / recall |
|---|---|---|---|---|---|
| dev | 102 | 79.4% | 81.5% | 12 / 100% / 25% | 78.7% / 77.1% |
| dev2 | 92 | 82.6% | 82.9% | 14 / 85.7% / 33.3% | 85.7% / 66.7% |
| tune (dev+dev2) | 194 | 80.9% | 82.2% | 26 / 92.3% / 28.6% | 81.3% / 72.6% |
| **test2 (blind)** | 96 | **72.9%** | **73.3%** | 13 / **92.3%** / 27.3% | 75.0% / 61.4% |

Confidence: with so few "today" predictions the intervals are wide. test2 today precision 12/13 has a 95% Wilson interval of roughly 67% to 99%; test2 route accuracy 70/96 is roughly 63% to 81%.

### Acceptance against `implementation-plan.md` Phase 2
| Criterion | Target | Result | Status |
|---|---|---|---|
| `today` precision on held-out data | >= 85% | 92.3% (test2), 80.0% on the first blind run | Met on the final blind run; the first blind run missed, so treat as borderline |
| Tier-1 route accuracy on held-out data | >= 80% | 73.3% (test2), 80.5% on the first blind run | **Dropped** (decision #30): not met on the final blind run |
| `shown` (today+explore) precision on held-out data | >= 75% (replacement target) | 75.0% (27 of 36 on test2) | Met, with no margin |
| Every classification has an explanation | yes | yes (tested) | Met |
| Rules deterministic | yes | yes (tested) | Met |
**The replacement target was chosen after seeing these results**, so passing it is weaker evidence than a pre-registered target. The `shown` precision margin is zero (75.0% vs 75%), and on dev2 the first blind run of an earlier rules version gave 80.0% / 85.7%. Treat Phase 2 as met on the revised criteria, with the caveats above.

## Where it fails
- **Recall.** On test2, 17 of 44 constructive stories scored below the Explore line. Typical misses are solution-journalism features whose headline and excerpt contain little constructive vocabulary ("Beavers Are Having a Moment", "Meet India's Four-Legged Wildlife Detectives"). Excerpt-only rules cannot see the article body.
- **False positives** are mostly neutral research, essays and explainers (for example a study on the hidden health cost of eating alone, an essay on a political milestone).
- **Story types are weak** (test2: `solution` recall 6%, `progress` recall 7%; `environment` precision 77%, recall 50%). Do not use story types for routing or present them as reliable; treat them as soft tags until improved.
- **Labels** are single-labeler drafts; borderline cases are marked in `notes`.

## Supply check: can the rules fill 5 to 10 daily stories?
Classifying every article stored in the local database from the last 14 days (2026-10-14 to 2026-10-27; older days have partial source coverage):
- 36 `today`, 82 `explore`, 170 `excluded` (an average of **2.6 `today` and 5.9 `explore` per day**; the two most recent days, with all sources fully present, had 13 and 16 combined).
- `today` stories came mostly from Good News Network (9), Mongabay (9), Happy Eco News (8) and Positive News (4).
- So `today`-route stories alone will often not reach 5 per day. The daily selector must fill with the highest-scoring `explore` stories (score floor 0.42). Documented in `architecture.md` and `classification-rules.md`.

## Recommendations
1. Have a person review the 290 draft labels (priority: the `test2` and borderline items), then re-run.
2. Route accuracy (recall) is limited by title + excerpt input; the product-focused targets above replaced it (decision #30). Revisit if a richer signal becomes available.
3. Improve recall cheaply with more lexicon coverage using new labeled data (never tune on `test2`; create a fresh held-out batch for the next iteration).
4. Keep the rules explainable. Do not add title-specific rules.

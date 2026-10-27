# Architecture

**Principle:** client-side first. There is no server we operate. The Android app fetches the curated RSS feeds directly when it is opened, and does all parsing, filtering, classification, de-duplication and selection on the device. The web app comes later (future milestone) and reads a pre-built static JSON file, because browsers block direct feed requests.

## Overview

```text
ANDROID (milestone 1)
  Curated RSS feeds
        |  HTTPS GET on app open (conditional, cached, parallel)
        v
  FeedFetcher -> Parser -> Normalizer -> Stage-1 filters -> De-duplication
        -> Rule-based classifier (rules.json) -> Ranker -> Daily selector (5-10/day)
        -> SQLite (Drift) -> UI (Today / Explore / Story / Saved / Preferences)

WEB (future milestone, after Android is done and tested)
  Scheduled export job (reuses tools/pipeline-prototype)
        -> static JSON on GitHub Pages / Netlify  (docs/static-feed-contract.md)
        -> Flutter web: StaticJsonFeedSource -> same ranker / selector / UI
```

## Why not read feeds in the browser?
Tested 2026-10-27: 1 of 10 active feeds sends CORS headers (Mongabay). The others cannot be fetched by a page on another origin. Native Android has no such restriction. See `source-allowlist.csv` (`browser_cors`).

## App layers (`app/lib/`)
| Folder | Responsibility |
|---|---|
| `domain/` | Plain models: `Source`, `Article`, `Classification`, `Preferences`, `DailyPick` |
| `data/sources/` | `StorySource` interface; `DirectRssStorySource` (Android), `StaticJsonStorySource` (web, future) |
| `data/db/` | Drift/SQLite tables, DAOs, migrations |
| `pipeline/` | Pure Dart, no Flutter imports, fully unit-testable: `canonicalize_url`, `dates`, `feed_parser`, `normalize`, `rules` (loads `rules.json`), `classifier`, `dedupe` |
| `classification/` | `ClassificationService`: classifies on insert; re-classifies stored articles after a rules update |
| `selection/` | Pure `rank` and `daily_selector`; `DedupeService` (cluster ids), `PreferencesRepository`, `DailyPicksService` |
| `features/` | `today`, `explore`, `story`, `saved`, `preferences` (UI + state) |
| `core/` | Riverpod providers, asset loading, clock, config |
| `ingestion/` | `IngestionService` (parallel refresh, TTL, backoff, retention) |

### StorySource contract
```dart
abstract class StorySource {
  /// Returns normalized candidates. `classification` is null when the device must classify.
  Future<SourceResult> load(Source source, {FetchState? previous});
}
```
- `DirectRssStorySource`: GET feed, parse RSS/Atom, normalize. Classification is done on device.
- `StaticJsonStorySource` (future): downloads the exported JSON; articles arrive already normalized and classified with a `rules_version`.

## Fetch-on-open flow
1. On app start, render the **cached** daily picks immediately (no spinner if they exist).
2. If the cache for a source is older than its TTL (default 30 min), fetch it. All enabled sources are fetched in parallel (concurrency 4), 10 s timeout each, 5 MB max body, conditional GET (ETag / Last-Modified). One failing source never blocks the rest.
3. New items run through `pipeline/` and are stored. Duplicates (canonical URL) are ignored, so repeated opens are idempotent.
4. If today has no picks yet (first open of the local day), the selector creates them. Picks are stored and stay stable all day. If the user raises "stories per day", the next best stories are appended.
5. Offline or all fetches failed: show today's picks, or otherwise the best cached stories, with a quiet "last updated" note.
Overall deadline for a refresh: 15 s. Honor `429`/`Retry-After`: back off that source for the rest of the session.

## Daily selection (5 to 10 stories, user setting)
- "Day" is the device's local calendar day. `stories_per_day` is an integer 5-10 (default 5).
- Candidates: `route = today` first, then `route = explore` to fill the quota when `today` has too few stories (measured supply is about 2.6 `today` and 5.9 `explore` per day). Excluded items are never candidates. All candidates must be unhidden, unseen, within the 14-day age window, and from enabled sources. **Stories picked on an earlier day never come back** (they count as seen).
- Rank (deterministic): `0.25*trust + 0.25*freshness + 0.40*constructive_score + 0.10*topic_match(max 2) - seen_penalty(0.30) - source_penalty`. Freshness halves every 36 hours. Preferred topics are a **boost, not a filter** (a filter could starve the day); sources are filtered by the on-device enabled flag.
- Selection passes, each by rank (ties: newest, then id, so input order never matters): (1) `today` stories, (2) `explore` stories, both with at most 2 per source and 3 per primary topic; if the quota is still unmet, (3) relax the topic cap, then (4) the source cap.
- One story per duplicate cluster (see below); a cluster that already has a pick today, or a seen story, is skipped.
- Picks are written once per local day and only ever appended: raising `stories_per_day` adds the next best stories, lowering it shows a prefix, a short day is topped up as more stories arrive.
- Never optimize for engagement.

## De-duplication
`pipeline/dedupe.dart` assigns a `cluster_id` (the earliest member's id) to stories published within 3 days of each other that match by (A) near-identical headlines (token Jaccard >= 0.6) or (B) IDF-weighted title cosine >= 0.30 with at least 2 shared rare words. It favours precision: a false merge would hide a legitimate story, while a missed duplicate only shows the same news twice. Same-story pairs with different framing can be missed (see `evaluation-report.md`). Recomputed after each refresh for the last 8 days.

## Storage
On-device SQLite via Drift: see `data-model.md`. Articles older than 30 days are pruned unless bookmarked. Bookmarks keep a snapshot (title, excerpt, source, url) for offline reading.

## Editorial control without a server
No human reviews stories at runtime. Control comes from: (1) the curated source allowlist; (2) versioned, tested rules (`rules/rules.json`: lexicons, thresholds, blocklists, per-source exclude patterns); (3) offline evaluation against the labeled set before every rules change; (4) user reporting stored locally and used to hide a story on that device; (5) maintainers shipping updated rules/sources in app releases (remote rules are a future milestone).

## What runs where
| Capability | Android app | Web (future) | `tools/pipeline-prototype` |
|---|---|---|---|
| Fetch feeds | On device | Export job | Reference / export job |
| Classify | Dart port | Precomputed in JSON | Python reference |
| Select daily picks | On device | On device | n/a |
| Human review | None at runtime | Optional via files/PR | Django admin (prototype) |
| Accounts, sync, push | Not in scope | Not in scope | n/a |

## Limitations (accepted)
- Classification works from title + feed excerpt only; no article text, so evidence signals are weak. Today's list is deliberately conservative.
- No cross-device sync; saves/preferences/feedback are per device.
- No shared de-duplication, ranking or flag-to-remove across users.
- Rule changes ship with app releases until remote rules exist.
- Each user's device contacts publishers directly (their servers see the request; see privacy notes).
- Feeds expose only recent items (10-100), so there is no deep history.

## Privacy
No backend, accounts, analytics or ads. The only network traffic is feed requests to the publishers and (when tapped) opening an article in the browser. Preferences, bookmarks and feedback stay on the device. Any future telemetry (crash reports) must be opt-in.

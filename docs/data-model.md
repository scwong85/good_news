# On-device Data Model (SQLite via Drift)

Created by Drift migrations in `app/lib/data/db/`. All timestamps are UTC ISO-8601 text or epoch ms. The original server (Postgres) model is archived in `tools/pipeline-prototype/DATA_MODEL.md`.

## sources
`id` (text pk, slug), `name`, `homepage_url`, `rss_url`, `tier` (1-3), `trust_score` (0-1), `language`, `regions` (json), `user_enabled` (bool), `etag`, `last_modified`, `last_fetched_at`, `last_status`, `consecutive_failures`, `backoff_until`.
Seeded from the bundled source list (generated from `docs/source-allowlist.csv`); only `user_enabled` and fetch bookkeeping change.

## articles
`id` (text pk = first 16 hex of sha1(canonical_url)), `source_id`, `canonical_url` (unique), `title`, `excerpt`, `published_at`, `fetched_at`, `language`, `regions` (json), `topics` (json), `story_types` (json), `evidence_signals` (json), `constructive_score`, `route` (`today|explore|excluded`), `explanation` (json), `rules_version`, `cluster_id` (nullable), `hidden` (bool).
Index `(route, published_at desc)`, unique `canonical_url`. Pruned after 30 days unless bookmarked.

## daily_picks (schema v2)
`day` (local date text), `position` (int), `article_id`; pk `(day, position)`. Written once per day; extended when `stories_per_day` increases.

## seen (schema v2)
`article_id` pk, `seen_at`.

## bookmarks
`article_id` pk, `saved_at`, `snapshot` (json: title, excerpt, source name, url, published_at) so saved items survive pruning and work offline.

## feedback (local only)
`id`, `article_id`, `signal` (`useful|too_trivial|not_credible|already_seen|not_for_me|made_my_day`), `created_at`. `not_credible` / report hides the article on this device and lowers ranking for its source.

## preferences (key-value, schema v2)
`stories_per_day` (5-10, default 5), `topics`, `regions`, `sensitivity`, `enabled_sources`, `reminder_time` (optional, local notification), `crash_reports_opt_in` (default false).

## Rules cache
`rules_version` currently in use; articles classified under an older version are reclassified lazily after an app update (cheap, since stored title/excerpt are enough).

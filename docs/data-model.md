# Data Model

PostgreSQL 16. All primary keys are UUIDs. Timestamps are timezone-aware UTC. The raw payload and normalized article are stored separately.

## Source
`id, name, homepage_url, rss_url, tier (1-3), trust_score (0-1), language, regions[], active, last_fetched_at, fetch_interval_minutes, robots_policy ('respect'), licensing_notes, include_rules, exclude_rules, reviewed_count, created_at, updated_at`

## IngestionRun
`id, source_id, started_at, finished_at, status (success|partial|failed), http_status, items_seen, items_created, items_skipped, error_message`
One row per fetch attempt; records success/failure per source.

## RawItem
`id, ingestion_run_id, source_id, external_id, payload (jsonb), fetched_at`
Unique `(source_id, external_id)`. Immutable.

## Article
`id, source_id, raw_item_id, external_id, canonical_url (unique), title, excerpt, published_at, language, regions[], topics[], story_types[], summary, why_it_matters, evidence_signals[], quality_score, constructive_score, classification_explanation (jsonb), duplicate_of_id, cluster_id, status, review_decision, reviewed_by, embedding (optional, vector/array), search_vector, created_at, updated_at`

### Status machine
`discovered -> filtered_out | pending_review | approved`
`pending_review -> approved | rejected`
`approved -> published -> archived | flagged`
`flagged -> pending_review`
Every transition writes an `ArticleStatusEvent(article_id, from, to, actor, reason, created_at)`.

## ReviewDecision
`id, article_id, reviewer, decision (approve|reject|edit|archive), rejection_reason, story_types[], topics[], notes, created_at`
Exported as labeled training data.

## ClassificationAudit
`id, article_id, stage, rules_version, features (jsonb), score, route, created_at`

## DuplicateCluster
`id, primary_article_id, created_at`; articles reference `cluster_id`.

## UserFeedback
`id, anonymous_id, article_id, signal (made_my_day|useful|too_trivial|not_credible|already_seen|not_for_me), created_at`
`not_credible` feedback beyond a threshold moves the article to `flagged`.

## Anonymous reader state
`Session(anonymous_id, preferences jsonb, created_at)`, `Bookmark(anonymous_id, article_id, created_at)`. No PII required; deletion endpoint removes all rows for an `anonymous_id`.

## Indexes
`Article(status, published_at desc)`, GIN on `topics`, `regions`, `search_vector`; unique `canonical_url`.

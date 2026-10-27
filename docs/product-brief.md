# Product Brief

**Good News Aggregator**: a calm, trustworthy Android app (web later) that gives you a small daily briefing of credible *constructive* news from vetted sources.

**Promise:** 5 to 10 stories a day (your setting) about credible progress, solutions and constructive developments. It is not an algorithmic positivity filter, and it never labels all global news as good or bad.

## Principles
1. Curated source allowlist only; no broad crawling.
2. **Client-side first:** the app fetches feeds itself when opened. No server, account or background sync is required.
3. Trust and calm over engagement: no infinite scroll, no streaks, no nags.
4. Transparent rule-based classification; every story shows why it was included. No LLM dependency.
5. Never republish full articles: headline, short excerpt, source, and a link to the original.
6. Private by default: no accounts, analytics or ads. Data stays on the device.

## How it works
Open the app -> cached picks appear immediately -> feeds refresh in the background of that session -> new items are filtered, classified and de-duplicated on the device -> today's picks (5-10) are fixed for the day.

## Delivery path
Android first. Web comes later as a future milestone, reading a pre-built static JSON file (browsers block direct feed requests). See `implementation-plan.md` and `architecture.md`.

## Screens
Today, Explore (topic/region/type filters and search over cached stories), Story detail, Saved (offline), Preferences (stories per day 5-10, topics, regions, sources, sensitivity).

## Success metrics (no telemetry; measured via manual studies and store feedback)
Useful rate of sampled stories, duplicate rate, rules precision on the labeled set, cached-launch time, fetch success rate in test runs, crash-free rate from the store.

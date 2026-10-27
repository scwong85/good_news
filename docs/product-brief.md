# Product Brief

**Good News Aggregator**: a calm, trustworthy, mobile-first app that aggregates credible *constructive* news from vetted sources.

**Promise:** a daily briefing on credible progress, solutions and constructive developments. It is not an algorithmic positivity filter, and it never labels all global news as good or bad.

## Principles
1. Curated allowlist first; no broad crawling at launch.
2. Trust and calm reading over engagement.
3. Deterministic rules + optional local models; external LLMs only enrich, never publish.
4. Never republish full articles: headline, short excerpt/summary, attribution, canonical link.
5. Anonymous reading, minimal data, no account needed.
6. Editorial decisions and user feedback are training data.

## Delivery path
One Flutter codebase builds the Android app and the web app. Web is hosted on GitHub Pages (static); the Django API is hosted separately. iOS can be added later from the same codebase.

## Screens (Phase 4/5, Flutter)
Today (5-10 stories), Explore (topic/region/type filters + search), Story detail, Saved, Preferences, Daily digest.

## Success metrics
Content quality (useful rate, evidence-signal rate, duplicate rate, editor override rate, flag rate); engagement (DAU, D7/D30 return, digest open, save rate); operations (ingestion success, latency, queue backlog, uptime).

Full plan: see the original implementation plan; phase tracking is in `decision-log.md`.

# API Contracts (v1, draft)

Base path `/api/v1`. JSON. Public read endpoints need no auth. Reader state is keyed by an anonymous id in the `X-Anonymous-Id` header (client-generated UUID).

## Public
| Method | Path | Notes |
|---|---|---|
| GET | `/feed/today` | 5-10 ranked published stories; no duplicates |
| GET | `/articles` | Filters: `topic`, `region`, `story_type`, `q` (full-text), `cursor`, `limit` |
| GET | `/articles/{id}` | Detail incl. `why_included` explanation |
| GET/PUT | `/preferences` | topics, regions, digest_time, sensitivity, notifications |
| GET/POST/DELETE | `/bookmarks`, `/bookmarks/{article_id}` | |
| POST | `/articles/{id}/feedback` | body `{signal}` |
| DELETE | `/me` | Delete all data for the anonymous id |
| POST | `/takedown` | Publisher/reader removal request |
| GET | `/health` | Liveness + latest ingestion status |

### Article (public shape)
```json
{
  "id": "uuid", "title": "", "summary": "", "why_it_matters": "",
  "source": {"id": "uuid", "name": "", "homepage_url": ""},
  "canonical_url": "", "published_at": "", "reading_time_minutes": 3,
  "topics": [], "regions": [], "story_types": [], "evidence_signals": [],
  "why_included": "Short explanation of the classification"
}
```
Never returns full article text.

## Implemented in Phase 1
`GET /health`, `GET /articles` (published only; `topic` filter; cursor pagination), `GET /articles/{id}`. Other endpoints arrive in Phases 4-5. The server-rendered feed is at `/`.

## Staff (Django admin, Phase 1/2 initially; REST later)
Review queue, approve/reject/edit/archive, source management, classification explanation, duplicate clusters, labeled-data export.

## Conventions
CORS must allow the GitHub Pages origin and local Flutter web dev. Cursor pagination; ISO-8601 UTC; errors `{ "error": {"code","message"} }`; rate limits on feedback and takedown.

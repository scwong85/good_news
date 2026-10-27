import logging
import time
from dataclasses import dataclass
from urllib.parse import urlsplit
from urllib.robotparser import RobotFileParser

import httpx
from django.conf import settings

log = logging.getLogger(__name__)


class FetchError(Exception):
    def __init__(self, message: str, http_status: int | None = None):
        super().__init__(message)
        self.http_status = http_status


@dataclass
class FetchResult:
    http_status: int
    content: bytes = b""
    etag: str = ""
    last_modified: str = ""
    not_modified: bool = False


def make_client() -> httpx.Client:
    return httpx.Client(
        timeout=settings.FETCH_TIMEOUT_SECONDS,
        follow_redirects=True,
        headers={
            "User-Agent": settings.INGESTION_USER_AGENT,
            "Accept": "application/rss+xml, application/atom+xml, application/xml;q=0.9, */*;q=0.5",
        },
    )


def fetch_feed(
    client: httpx.Client, url: str, *, etag: str = "", last_modified: str = ""
) -> FetchResult:
    """GET a feed with conditional headers, bounded size and a small retry on transient errors."""
    headers = {}
    if etag:
        headers["If-None-Match"] = etag
    if last_modified:
        headers["If-Modified-Since"] = last_modified
    last_error: FetchError | None = None
    for attempt in range(settings.FETCH_RETRIES + 1):
        if attempt:
            time.sleep(settings.FETCH_RETRY_BACKOFF_SECONDS * attempt)
        try:
            resp = client.get(url, headers=headers)
        except httpx.HTTPError as exc:
            last_error = FetchError(f"{type(exc).__name__}: {exc}")
            continue
        if resp.status_code == 304:
            return FetchResult(304, not_modified=True, etag=etag, last_modified=last_modified)
        if resp.status_code >= 500 or resp.status_code == 429:
            last_error = FetchError(f"HTTP {resp.status_code}", resp.status_code)
            continue
        if resp.status_code >= 400:
            raise FetchError(f"HTTP {resp.status_code}", resp.status_code)
        if len(resp.content) > settings.FETCH_MAX_BYTES:
            raise FetchError(f"feed larger than {settings.FETCH_MAX_BYTES} bytes", resp.status_code)
        return FetchResult(
            resp.status_code,
            resp.content,
            etag=resp.headers.get("etag", ""),
            last_modified=resp.headers.get("last-modified", ""),
        )
    assert last_error is not None
    raise last_error


def robots_allows(client: httpx.Client, url: str, cache: dict[str, RobotFileParser | None]) -> bool:
    """True when robots.txt permits our agent to fetch `url`.

    4xx on robots.txt means no restrictions; network errors and 5xx are treated as
    "not allowed" (conservative) so the run is skipped and retried later.
    """
    parts = urlsplit(url)
    origin = f"{parts.scheme}://{parts.netloc}"
    if origin not in cache:
        parser: RobotFileParser | None = RobotFileParser()
        try:
            resp = client.get(f"{origin}/robots.txt")
            if resp.status_code >= 500:
                parser = None
            elif resp.status_code >= 400:
                parser.parse([])
            else:
                parser.parse(resp.text.splitlines())
        except httpx.HTTPError:
            log.warning("robots.txt fetch failed for %s", origin)
            parser = None
        cache[origin] = parser
    parser = cache[origin]
    if parser is None:
        return False
    path = parts.path + (f"?{parts.query}" if parts.query else "")
    return parser.can_fetch(settings.ROBOTS_AGENT_TOKEN, f"{origin}{path}")

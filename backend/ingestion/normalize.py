"""Turn a feedparser entry into a normalized item. Pure functions, no DB access."""

import html
import re
import unicodedata
import warnings
from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta

from bs4 import BeautifulSoup, MarkupResemblesLocatorWarning
from django.conf import settings
from langdetect import DetectorFactory, LangDetectException, detect

from .urls import InvalidURL, canonicalize_url

DetectorFactory.seed = 0
warnings.filterwarnings("ignore", category=MarkupResemblesLocatorWarning)

TITLE_MAX = 500
# Feed category -> editorial topic (deterministic; full topic rules arrive in Phase 2)
TOPIC_ALIASES = {
    "environment": "environment",
    "climate": "environment",
    "nature": "environment",
    "wildlife": "environment",
    "conservation": "environment",
    "science": "science",
    "health": "health",
    "medicine": "health",
    "education": "education",
    "technology": "technology",
    "tech": "technology",
    "community": "community",
    "development": "development",
    "society": "society",
    "culture": "culture",
}
_WP_BOILERPLATE = re.compile(r"\s*The post .{0,500}? appeared first on .*$", re.DOTALL)


class SkipItem(Exception):
    """Item cannot be ingested; `reason` is a short machine-readable code."""

    def __init__(self, reason: str):
        super().__init__(reason)
        self.reason = reason


@dataclass
class NormalizedItem:
    external_id: str
    canonical_url: str
    title: str
    excerpt: str
    published_at: datetime
    language: str
    regions: list[str] = field(default_factory=list)
    topics: list[str] = field(default_factory=list)


def clean_text(value: str) -> str:
    text = BeautifulSoup(value or "", "html.parser").get_text(" ")
    text = unicodedata.normalize("NFC", html.unescape(text))
    return re.sub(r"\s+", " ", text).strip()


def truncate(text: str, limit: int) -> str:
    if len(text) <= limit:
        return text
    cut = text[:limit].rsplit(" ", 1)[0].rstrip(" ,;:-")
    return f"{cut}…"


def make_excerpt(entry, title: str) -> str:
    raw = entry.get("summary") or ""
    if not raw and entry.get("content"):
        raw = entry["content"][0].get("value", "")
    text = _WP_BOILERPLATE.sub("", clean_text(raw)).strip()
    if text.startswith(title):
        text = text[len(title) :].strip()
    return truncate(text, settings.EXCERPT_MAX_CHARS)


def parse_published(entry, now: datetime) -> datetime:
    struct = entry.get("published_parsed") or entry.get("updated_parsed")
    if not struct:
        raise SkipItem("missing_date")
    published = datetime(*struct[:6], tzinfo=UTC)
    return min(published, now + timedelta(days=1))  # clamp far-future dates


def detect_language(text: str, default: str) -> str:
    if len(text) < 40:
        return default
    try:
        return detect(text)
    except LangDetectException:
        return default


def topics_from_entry(entry) -> list[str]:
    topics: list[str] = []
    for tag in entry.get("tags") or []:
        topic = TOPIC_ALIASES.get((tag.get("term") or "").strip().lower())
        if topic and topic not in topics:
            topics.append(topic)
    return topics


def normalize_entry(entry, source, now: datetime) -> NormalizedItem:
    link = entry.get("link") or ""
    if not link:
        raise SkipItem("missing_url")
    try:
        canonical = canonicalize_url(link)
    except InvalidURL:
        raise SkipItem("invalid_url") from None
    title = truncate(clean_text(entry.get("title") or ""), TITLE_MAX)
    if not title:
        raise SkipItem("missing_title")
    excerpt = make_excerpt(entry, title)
    return NormalizedItem(
        external_id=(entry.get("id") or link)[:1000],
        canonical_url=canonical,
        title=title,
        excerpt=excerpt,
        published_at=parse_published(entry, now),
        language=detect_language(f"{title}. {excerpt}", source.language),
        regions=list(source.regions or []),
        topics=topics_from_entry(entry),
    )

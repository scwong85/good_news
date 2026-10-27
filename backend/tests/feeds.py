"""Helpers that build fixture feeds with dates relative to now."""

from datetime import UTC, datetime, timedelta
from email.utils import format_datetime
from pathlib import Path

FIXTURES = Path(__file__).parent / "fixtures" / "feeds"


def days_ago(n: float) -> datetime:
    return datetime.now(UTC) - timedelta(days=n)


def rss_item(title, link, *, when=None, desc="", guid=None, categories=(), no_date=False):
    date = "" if no_date else f"<pubDate>{format_datetime(when or days_ago(1))}</pubDate>"
    cats = "".join(f"<category>{c}</category>" for c in categories)
    return (
        f"<item><title>{title}</title><link>{link}</link><guid>{guid or link}</guid>"
        f"{date}<description><![CDATA[{desc}]]></description>{cats}</item>"
    )


def rss(*items: str) -> bytes:
    return (
        '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel>'
        "<title>Test Feed</title><link>https://example.com</link><description>t</description>"
        + "".join(items)
        + "</channel></rss>"
    ).encode()


def atom(title, link, when=None) -> bytes:
    when = when or days_ago(1)
    return (
        '<?xml version="1.0" encoding="utf-8"?><feed xmlns="http://www.w3.org/2005/Atom">'
        f"<title>Atom</title><id>urn:feed</id><updated>{when.isoformat()}</updated>"
        f'<entry><title>{title}</title><link href="{link}"/><id>urn:entry:1</id>'
        f"<updated>{when.isoformat()}</updated><summary>An atom entry about restoring wetlands "
        "with volunteers and measurable results.</summary></entry></feed>"
    ).encode()

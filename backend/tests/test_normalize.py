from datetime import UTC, datetime

import feedparser
import pytest

from ingestion.normalize import SkipItem, clean_text, normalize_entry, truncate

from .feeds import rss, rss_item


def first_entry(*items):
    return feedparser.parse(rss(*items)).entries[0]


def test_clean_text_strips_html_and_entities():
    assert (
        clean_text("<p>Hello&nbsp;<b>world</b> &amp; friends</p>\n\n  ok")
        == "Hello world & friends ok"
    )


def test_truncate_on_word_boundary():
    out = truncate("alpha beta gamma delta", 12)
    assert out == "alpha beta…" and len(out) <= 12


def test_normalize_basic(source, settings):
    settings.EXCERPT_MAX_CHARS = 60
    entry = first_entry(
        rss_item(
            "  Wetlands <i>restored</i>  ",
            "http://Example.com/wet/?utm_source=nl",
            desc="<p>Volunteers restored 40 hectares of wetland. " + "More detail. " * 20 + "</p>",
            categories=("Environment", "Weird Tag", "Climate"),
        )
    )
    item = normalize_entry(entry, source, datetime.now(UTC))
    assert item.title == "Wetlands restored"
    assert item.canonical_url == "https://example.com/wet"
    assert item.excerpt.startswith("Volunteers restored 40 hectares") and len(item.excerpt) <= 60
    assert item.topics == ["environment"]
    assert item.regions == ["global"] and item.published_at.tzinfo is not None


def test_wordpress_boilerplate_and_title_echo_removed(source):
    entry = first_entry(
        rss_item(
            "Solar farms shelter owls",
            "https://example.com/owls",
            desc=(
                "Solar farms shelter owls Burrowing owls thrive. "
                "The post Solar farms shelter owls appeared first on Example."
            ),
        )
    )
    assert normalize_entry(entry, source, datetime.now(UTC)).excerpt == "Burrowing owls thrive."


@pytest.mark.parametrize(
    "item,reason",
    [
        (rss_item("No date", "https://example.com/a", no_date=True), "missing_date"),
        (rss_item("Bad scheme", "ftp://example.com/a"), "invalid_url"),
        (rss_item("", "https://example.com/a"), "missing_title"),
    ],
)
def test_skip_reasons(source, item, reason):
    with pytest.raises(SkipItem) as exc:
        normalize_entry(first_entry(item), source, datetime.now(UTC))
    assert exc.value.reason == reason


def test_future_date_is_clamped(source):
    from datetime import timedelta

    far = datetime.now(UTC) + timedelta(days=400)
    entry = first_entry(rss_item("Future", "https://example.com/f", when=far))
    now = datetime.now(UTC)
    assert normalize_entry(entry, source, now).published_at <= now + timedelta(days=1)


def test_language_detection_falls_back_for_short_text(source):
    entry = first_entry(rss_item("Hi", "https://example.com/h"))
    assert normalize_entry(entry, source, datetime.now(UTC)).language == "en"

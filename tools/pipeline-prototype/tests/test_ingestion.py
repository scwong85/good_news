import httpx
from django.utils import timezone

from articles.models import Article, ArticleStatusEvent
from ingestion.models import IngestionRun, RawItem
from ingestion.service import feed_page_url, ingest_source
from ingestion.tasks import ingest_due_sources
from sources.models import Source

from .feeds import FIXTURES, atom, days_ago, rss, rss_item

FEED = "https://example.com/feed/"


def feed_with(*items):
    return httpx.Response(
        200, content=rss(*items), headers={"content-type": "application/rss+xml", "etag": '"v1"'}
    )


def two_items():
    return feed_with(
        rss_item(
            "Rivers recovering", "https://example.com/rivers?utm_source=x", desc="Fish returned."
        ),
        rss_item("Clinic opens", "https://example.com/clinic", desc="Free care."),
    )


def test_ingests_and_normalizes(source, mock_web):
    mock_web.get(FEED).mock(return_value=two_items())
    run = ingest_source(source)
    assert run.status == "success" and (run.items_seen, run.items_created) == (2, 2)
    assert run.http_status == 200 and run.finished_at is not None
    assert set(Article.objects.values_list("canonical_url", flat=True)) == {
        "https://example.com/rivers",
        "https://example.com/clinic",
    }
    article = Article.objects.get(title="Clinic opens")
    assert article.status == "pending_review"
    assert article.raw_item.payload["title"] == "Clinic opens"  # raw kept separately
    event = ArticleStatusEvent.objects.get(article=article)
    assert (event.from_status, event.to_status, event.actor) == ("", "pending_review", "ingestion")
    source.refresh_from_db()
    assert source.last_fetched_at is not None and source.etag == '"v1"'


def test_rerun_creates_no_duplicates(source, mock_web):
    mock_web.get(FEED).mock(return_value=two_items())
    ingest_source(source)
    second = ingest_source(source, force=True)
    assert (second.items_created, second.items_skipped) == (0, 2)
    assert Article.objects.count() == 2 and RawItem.objects.count() == 2


def test_same_story_with_variant_urls_is_not_duplicated(source, mock_web):
    mock_web.get(FEED).mock(
        return_value=feed_with(
            rss_item("Story", "https://example.com/s/?utm_campaign=a", guid="g1"),
            rss_item("Story again", "http://EXAMPLE.com/s", guid="g2"),
        )
    )
    run = ingest_source(source)
    assert (run.items_created, run.items_skipped) == (1, 1)
    assert Article.objects.count() == 1


def test_same_url_in_two_sources_is_stored_once(source, mock_web):
    other = Source.objects.create(
        name="Other",
        homepage_url="https://example.com",
        rss_url="https://example.com/other-feed/",
        active=True,
        licensing_notes="x",
    )
    mock_web.get(FEED).mock(
        return_value=feed_with(rss_item("Shared", "https://example.com/shared"))
    )
    mock_web.get("https://example.com/other-feed/").mock(
        return_value=feed_with(rss_item("Shared", "https://example.com/shared"))
    )
    ingest_source(source)
    run = ingest_source(other)
    assert run.items_created == 0 and Article.objects.count() == 1


def test_bad_items_are_skipped_not_fatal(source, mock_web):
    mock_web.get(FEED).mock(
        return_value=feed_with(
            rss_item("Good", "https://example.com/good"),
            rss_item("No date", "https://example.com/nodate", no_date=True),
            rss_item("FTP", "ftp://example.com/x"),
        )
    )
    run = ingest_source(source)
    assert run.status == "success" and (run.items_created, run.items_skipped) == (1, 2)


def test_old_articles_are_filtered_out_not_pending(source, mock_web, settings):
    settings.ARTICLE_MAX_AGE_DAYS = 14
    mock_web.get(FEED).mock(
        return_value=feed_with(
            rss_item("Old", "https://example.com/old", when=days_ago(30)),
            rss_item("New", "https://example.com/new", when=days_ago(1)),
        )
    )
    ingest_source(source)
    assert Article.objects.get(title="Old").status == "filtered_out"
    assert Article.objects.get(title="New").status == "pending_review"
    # Reruns do not reprocess the filtered one
    assert ingest_source(source, force=True).items_created == 0


def test_max_age_zero_disables_filter(source, mock_web):
    mock_web.get(FEED).mock(
        return_value=feed_with(rss_item("Old", "https://example.com/old", when=days_ago(300)))
    )
    ingest_source(source, max_age_days=0)
    assert Article.objects.get().status == "pending_review"


def test_malformed_feed_is_recorded_not_raised(source, mock_web):
    mock_web.get(FEED).mock(
        return_value=httpx.Response(200, content=(FIXTURES / "malformed.xml").read_bytes())
    )
    run = ingest_source(source)
    assert run.status == "failed" and run.error_message
    assert Article.objects.count() == 0


def test_empty_feed_is_success(source, mock_web):
    mock_web.get(FEED).mock(return_value=feed_with())
    run = ingest_source(source)
    assert run.status == "success" and run.items_seen == 0


def test_http_error_recorded(source, mock_web):
    mock_web.get(FEED).mock(return_value=httpx.Response(404))
    run = ingest_source(source)
    assert (run.status, run.http_status) == ("failed", 404)


def test_server_error_is_retried_then_fails(source, mock_web):
    route = mock_web.get(FEED).mock(return_value=httpx.Response(503))
    run = ingest_source(source)
    assert run.status == "failed" and route.call_count == 2  # initial + 1 retry


def test_transient_error_recovers_on_retry(source, mock_web):
    mock_web.get(FEED).mock(side_effect=[httpx.ConnectError("boom"), two_items()])
    run = ingest_source(source)
    assert run.status == "success" and run.items_created == 2


def test_network_failure_recorded(source, mock_web):
    mock_web.get(FEED).mock(side_effect=httpx.ConnectError("down"))
    run = ingest_source(source)
    assert run.status == "failed" and "ConnectError" in run.error_message


def test_atom_feed(source, mock_web):
    mock_web.get(FEED).mock(
        return_value=httpx.Response(200, content=atom("Wetlands", "https://example.com/wet"))
    )
    run = ingest_source(source)
    assert run.items_created == 1 and Article.objects.get().title == "Wetlands"


def test_conditional_get_not_modified(source, mock_web):
    route = mock_web.get(FEED).mock(side_effect=[two_items(), httpx.Response(304)])
    ingest_source(source)
    source.refresh_from_db()
    run = ingest_source(source, force=False)  # not due yet -> skipped, no request
    assert run.status == "skipped" and route.call_count == 1
    Source.objects.filter(pk=source.pk).update(last_fetched_at=days_ago(1))
    source.refresh_from_db()
    run = ingest_source(source)
    assert run.status == "success" and run.error_message == "not modified"
    assert route.calls.last.request.headers["if-none-match"] == '"v1"'


def test_one_failing_item_makes_run_partial(source, mock_web, monkeypatch):
    from ingestion import service

    real = service.normalize_entry

    def flaky(entry, src, now):
        if entry.get("title") == "Boom":
            raise RuntimeError("bad item")
        return real(entry, src, now)

    monkeypatch.setattr(service, "normalize_entry", flaky)
    mock_web.get(FEED).mock(
        return_value=feed_with(
            rss_item("Boom", "https://example.com/b"), rss_item("Fine", "https://example.com/f")
        )
    )
    run = ingest_source(source)
    assert run.status == "partial" and (run.items_created, run.items_failed) == (1, 1)


# --- before_ingestion hook --------------------------------------------------


def test_inactive_source_is_skipped_without_fetching(source, mock_web):
    route = mock_web.get(FEED).mock(return_value=two_items())
    Source.objects.filter(pk=source.pk).update(active=False)
    source.refresh_from_db()
    run = ingest_source(source)
    assert run.status == "skipped" and "not active" in run.error_message and not route.called


def test_missing_licensing_note_blocks(source, mock_web):
    route = mock_web.get(FEED).mock(return_value=two_items())
    source.licensing_notes = ""
    source.save()
    assert ingest_source(source).status == "skipped" and not route.called


def test_robots_disallow_blocks(source, mock_web):
    route = mock_web.get(FEED).mock(return_value=two_items())
    mock_web.get("https://example.com/robots.txt").mock(
        return_value=httpx.Response(200, text="User-agent: *\nDisallow: /feed/\n")
    )
    run = ingest_source(source)
    assert run.status == "skipped" and "robots" in run.error_message and not route.called


def test_robots_5xx_is_conservative(source, mock_web):
    mock_web.get(FEED).mock(return_value=two_items())
    mock_web.get("https://example.com/robots.txt").mock(return_value=httpx.Response(503))
    assert ingest_source(source).status == "skipped"


def test_robots_missing_means_allowed(source, mock_web):
    mock_web.get(FEED).mock(return_value=two_items())
    mock_web.get("https://example.com/robots.txt").mock(return_value=httpx.Response(404))
    assert ingest_source(source).status == "success"


# --- backfill + tasks --------------------------------------------------------


def test_feed_page_url():
    assert feed_page_url("https://e.com/feed/", None) == "https://e.com/feed/"
    assert feed_page_url("https://e.com/feed/", 3) == "https://e.com/feed/?paged=3"
    assert feed_page_url("https://e.com/feed?x=1", 2) == "https://e.com/feed?x=1&paged=2"


def test_backfill_command_pages_until_no_new(source, mock_web):
    from django.core.management import call_command

    mock_web.get(FEED, params={"paged": "2"}).mock(
        return_value=feed_with(rss_item("P2", "https://example.com/p2"))
    )
    mock_web.get(FEED, params={"paged": "3"}).mock(
        return_value=feed_with(rss_item("P2", "https://example.com/p2"))
    )
    mock_web.get(FEED).mock(return_value=feed_with(rss_item("P1", "https://example.com/p1")))
    call_command(
        "ingest", "--source", "Test Source", "--backfill-pages", "5", "--max-age-days", "0"
    )
    assert set(Article.objects.values_list("title", flat=True)) == {"P1", "P2"}
    assert IngestionRun.objects.count() == 3  # p1, p2, p3 (no new -> stop)


def test_ingest_due_sources_task(source, mock_web):
    mock_web.get(FEED).mock(return_value=two_items())
    assert ingest_due_sources() == 1
    assert Article.objects.count() == 2
    assert ingest_due_sources() == 0  # interval not elapsed


def test_after_ingestion_handlers_run_and_failures_are_contained(source, mock_web):
    from ingestion import hooks

    seen = []
    hooks.register_after_ingestion(lambda run: seen.append(run.pk))
    hooks.register_after_ingestion(lambda run: 1 / 0)
    try:
        mock_web.get(FEED).mock(return_value=two_items())
        run = ingest_source(source)
        assert run.status == "success" and seen == [run.pk]
    finally:
        hooks._after_ingestion_handlers.clear()


def test_run_counts_are_recorded_per_source(source, mock_web):
    mock_web.get(FEED).mock(return_value=two_items())
    ingest_source(source)
    assert IngestionRun.objects.filter(source=source, status="success").count() == 1
    assert timezone.now() >= IngestionRun.objects.get().started_at

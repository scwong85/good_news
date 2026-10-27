import logging
from datetime import UTC, datetime, timedelta
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

import feedparser
import httpx
from django.conf import settings
from django.db import IntegrityError, transaction

from articles.models import Article
from articles.services import create_status_event
from sources.models import Source

from . import hooks
from .fetch import FetchError, fetch_feed, make_client
from .models import IngestionRun, RawItem
from .normalize import SkipItem, normalize_entry

log = logging.getLogger(__name__)


def feed_page_url(url: str, page: int | None) -> str:
    """WordPress-style pagination (`?paged=N`) used for backfill."""
    if not page or page == 1:
        return url
    parts = urlsplit(url)
    query = dict(parse_qsl(parts.query))
    query["paged"] = str(page)
    return urlunsplit(parts._replace(query=urlencode(query)))


def _jsonable(entry) -> dict:
    import json

    return json.loads(json.dumps(entry, default=str))


def _finish(run: IngestionRun, status: str, error: str = "") -> IngestionRun:
    run.status = status
    run.error_message = error[:2000]
    run.finished_at = datetime.now(UTC)
    run.save()
    return run


def ingest_source(
    source: Source,
    *,
    force: bool = False,
    page: int | None = None,
    max_age_days: int | None = None,
    client: httpx.Client | None = None,
    robots_cache: dict | None = None,
) -> IngestionRun:
    """Fetch one source and store new articles. Safe to rerun: canonical URLs are unique.

    `max_age_days`: None uses settings.ARTICLE_MAX_AGE_DAYS; 0 disables the age filter.
    Never raises for feed problems; the outcome is recorded on the returned IngestionRun.
    """
    now = datetime.now(UTC)
    url = feed_page_url(source.rss_url, page)
    run = IngestionRun.objects.create(source=source, requested_url=url, started_at=now)
    own_client = client is None
    client = client or make_client()
    try:
        check = hooks.before_ingestion(
            source,
            url=url,
            now=now,
            client=client,
            robots_cache=robots_cache if robots_cache is not None else {},
            force=force,
        )
        if not check.ok:
            return _finish(run, IngestionRun.Status.SKIPPED, check.reason)
        return _ingest(run, source, url, client, now, force, page, max_age_days)
    except Exception as exc:  # last-resort guard: a bad source must not crash the worker
        log.exception("ingestion crashed for %s", source)
        return _finish(run, IngestionRun.Status.FAILED, f"unexpected error: {exc}")
    finally:
        if own_client:
            client.close()


def _ingest(run, source, url, client, now, force, page, max_age_days) -> IngestionRun:
    conditional = not force and not page
    try:
        result = fetch_feed(
            client,
            url,
            etag=source.etag if conditional else "",
            last_modified=source.last_modified if conditional else "",
        )
    except FetchError as exc:
        run.http_status = exc.http_status
        return _finish(run, IngestionRun.Status.FAILED, str(exc))
    run.http_status = result.http_status
    if not page:
        Source.objects.filter(pk=source.pk).update(last_fetched_at=now)
    if result.not_modified:
        return _finish(run, IngestionRun.Status.SUCCESS, "not modified")

    parsed = feedparser.parse(result.content)
    entries = parsed.entries
    if not entries and parsed.bozo:
        return _finish(
            run, IngestionRun.Status.FAILED, f"unparseable feed: {parsed.bozo_exception}"
        )
    if not page:
        Source.objects.filter(pk=source.pk).update(
            etag=result.etag, last_modified=result.last_modified
        )

    age_days = settings.ARTICLE_MAX_AGE_DAYS if max_age_days is None else max_age_days
    cutoff = now - timedelta(days=age_days) if age_days else None
    errors: list[str] = []
    for entry in entries:
        run.items_seen += 1
        try:
            outcome = _store_entry(entry, source, run, now, cutoff)
        except SkipItem as skip:
            run.items_skipped += 1
            log.info("skipped item from %s: %s", source.name, skip.reason)
            continue
        except Exception as exc:
            run.items_failed += 1
            errors.append(f"{type(exc).__name__}: {exc}")
            log.exception("failed item from %s", source.name)
            continue
        if outcome == "created":
            run.items_created += 1
        else:
            run.items_skipped += 1

    if run.items_failed:
        _finish(run, IngestionRun.Status.PARTIAL, "; ".join(errors[:3]))
    else:
        note = f"feed had parse warnings: {parsed.bozo_exception}" if parsed.bozo else ""
        _finish(run, IngestionRun.Status.SUCCESS, note)
    hooks.after_ingestion(run)
    return run


def _store_entry(entry, source: Source, run: IngestionRun, now: datetime, cutoff) -> str:
    item = normalize_entry(entry, source, now)
    try:
        with transaction.atomic():
            if Article.objects.filter(canonical_url=item.canonical_url).exists():
                return "duplicate"
            raw, _ = RawItem.objects.get_or_create(
                source=source,
                external_id=item.external_id,
                defaults={"ingestion_run": run, "payload": _jsonable(entry)},
            )
            filtered = cutoff is not None and item.published_at < cutoff
            article = Article.objects.create(
                source=source,
                raw_item=raw,
                external_id=item.external_id,
                canonical_url=item.canonical_url,
                title=item.title,
                excerpt=item.excerpt,
                published_at=item.published_at,
                language=item.language,
                regions=item.regions,
                topics=item.topics,
                status=Article.Status.FILTERED_OUT if filtered else Article.Status.PENDING_REVIEW,
                classification_explanation={"stage1": {"filtered": "too_old"}} if filtered else {},
            )
            create_status_event(article, "", article.status, "ingestion", f"run {run.pk}")
            return "created"
    except IntegrityError:
        return "duplicate"  # lost a race on canonical_url / raw item uniqueness

"""Pipeline hooks (docs/pipeline-hooks.md): before_ingestion and after_ingestion."""

import logging
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime, timedelta

import httpx

from sources.models import Source

from .fetch import robots_allows
from .models import IngestionRun

log = logging.getLogger(__name__)


@dataclass
class HookResult:
    ok: bool
    reason: str = ""


def is_due(source: Source, now: datetime) -> bool:
    if source.last_fetched_at is None:
        return True
    return now - source.last_fetched_at >= timedelta(minutes=source.fetch_interval_minutes)


def before_ingestion(
    source: Source,
    *,
    url: str,
    now: datetime,
    client: httpx.Client,
    robots_cache: dict,
    force: bool = False,
) -> HookResult:
    """Source is active and licensed, within its fetch interval, and robots.txt allows the feed."""
    if not source.active:
        return HookResult(False, "source is not active")
    if not source.licensing_notes.strip():
        return HookResult(False, "source has no licensing note")
    if not force and not is_due(source, now):
        return HookResult(False, "not due (fetch interval not elapsed)")
    if source.robots_policy == "respect" and not robots_allows(client, url, robots_cache):
        return HookResult(False, "robots.txt disallows (or could not be read)")
    return HookResult(True)


_after_ingestion_handlers: list[Callable[[IngestionRun], None]] = []


def register_after_ingestion(handler: Callable[[IngestionRun], None]) -> None:
    """Later phases register classification and deduplication here."""
    _after_ingestion_handlers.append(handler)


def after_ingestion(run: IngestionRun) -> None:
    for handler in _after_ingestion_handlers:
        try:
            handler(run)
        except Exception:
            log.exception("after_ingestion handler %s failed for run %s", handler, run.pk)

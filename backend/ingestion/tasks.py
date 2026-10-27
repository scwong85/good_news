from datetime import UTC, datetime

from celery import shared_task

from sources.models import Source

from .hooks import is_due
from .service import ingest_source


@shared_task(acks_late=True)
def ingest_source_task(source_id: str, force: bool = False) -> str:
    run = ingest_source(Source.objects.get(pk=source_id), force=force)
    return f"{run.status}: created {run.items_created}"


@shared_task
def ingest_due_sources() -> int:
    """Beat entry point: enqueue every active source whose fetch interval has elapsed."""
    now = datetime.now(UTC)
    count = 0
    for source in Source.objects.filter(active=True):
        if is_due(source, now):
            ingest_source_task.delay(str(source.pk))
            count += 1
    return count

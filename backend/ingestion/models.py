import uuid

from django.db import models

from sources.models import Source


class IngestionRun(models.Model):
    class Status(models.TextChoices):
        RUNNING = "running"
        SUCCESS = "success"
        PARTIAL = "partial"
        FAILED = "failed"
        SKIPPED = "skipped"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    source = models.ForeignKey(Source, on_delete=models.CASCADE, related_name="ingestion_runs")
    requested_url = models.URLField(max_length=2000)
    started_at = models.DateTimeField()
    finished_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.RUNNING)
    http_status = models.PositiveSmallIntegerField(null=True, blank=True)
    items_seen = models.PositiveIntegerField(default=0)
    items_created = models.PositiveIntegerField(default=0)
    items_skipped = models.PositiveIntegerField(default=0)
    items_failed = models.PositiveIntegerField(default=0)
    error_message = models.TextField(blank=True)

    class Meta:
        ordering = ["-started_at"]
        indexes = [models.Index(fields=["source", "-started_at"], name="run_source_started_idx")]

    def __str__(self) -> str:
        return f"{self.source} {self.status} {self.started_at:%Y-%m-%d %H:%M}"


class RawItem(models.Model):
    """Immutable raw feed entry, kept separate from the normalized Article."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ingestion_run = models.ForeignKey(
        IngestionRun, on_delete=models.CASCADE, related_name="raw_items"
    )
    source = models.ForeignKey(Source, on_delete=models.CASCADE, related_name="raw_items")
    external_id = models.CharField(max_length=1000)
    payload = models.JSONField()
    fetched_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["source", "external_id"], name="raw_item_unique_per_source"
            )
        ]

    def __str__(self) -> str:
        return f"{self.source}: {self.external_id}"

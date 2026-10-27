import uuid

from django.db import models

from sources.models import Source

from .constants import REJECTION_REASONS


class Article(models.Model):
    class Status(models.TextChoices):
        DISCOVERED = "discovered"
        FILTERED_OUT = "filtered_out"
        PENDING_REVIEW = "pending_review"
        APPROVED = "approved"
        REJECTED = "rejected"
        PUBLISHED = "published"
        ARCHIVED = "archived"
        FLAGGED = "flagged"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    source = models.ForeignKey(Source, on_delete=models.PROTECT, related_name="articles")
    raw_item = models.OneToOneField(
        "ingestion.RawItem",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="article",
    )
    external_id = models.CharField(max_length=1000)
    canonical_url = models.URLField(max_length=2000, unique=True)
    title = models.CharField(max_length=500)
    excerpt = models.TextField(blank=True)
    published_at = models.DateTimeField()
    language = models.CharField(max_length=8, blank=True)
    # Lists are JSON (portable, simple); promote to ArrayField + GIN when filters need it (Phase 4).
    regions = models.JSONField(default=list, blank=True)
    topics = models.JSONField(default=list, blank=True)
    story_types = models.JSONField(default=list, blank=True)
    summary = models.TextField(blank=True)
    why_it_matters = models.TextField(blank=True)
    evidence_signals = models.JSONField(default=list, blank=True)
    quality_score = models.FloatField(null=True, blank=True)
    constructive_score = models.FloatField(null=True, blank=True)
    classification_explanation = models.JSONField(default=dict, blank=True)
    duplicate_of = models.ForeignKey(
        "self", null=True, blank=True, on_delete=models.SET_NULL, related_name="duplicates"
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.DISCOVERED)
    review_decision = models.CharField(max_length=20, blank=True)
    rejection_reason = models.CharField(
        max_length=32, blank=True, choices=[(r, r) for r in REJECTION_REASONS]
    )
    reviewed_by = models.CharField(max_length=150, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-published_at"]
        indexes = [models.Index(fields=["status", "-published_at"], name="article_status_pub_idx")]

    def __str__(self) -> str:
        return self.title


class ArticleStatusEvent(models.Model):
    """Append-only status history (docs/editorial-policy.md: preserve status history)."""

    article = models.ForeignKey(Article, on_delete=models.CASCADE, related_name="status_events")
    from_status = models.CharField(max_length=20, blank=True)
    to_status = models.CharField(max_length=20)
    actor = models.CharField(max_length=150, default="system")
    reason = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at", "id"]

    def __str__(self) -> str:
        return f"{self.from_status or 'new'} -> {self.to_status}"

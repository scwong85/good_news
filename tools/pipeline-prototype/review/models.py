from django.db import models

from articles.constants import REJECTION_REASONS
from articles.models import Article


class ReviewDecision(models.Model):
    class Decision(models.TextChoices):
        APPROVE = "approve"
        REJECT = "reject"
        EDIT = "edit"
        ARCHIVE = "archive"

    article = models.ForeignKey(Article, on_delete=models.CASCADE, related_name="review_decisions")
    reviewer = models.CharField(max_length=150)
    decision = models.CharField(max_length=10, choices=Decision.choices)
    rejection_reason = models.CharField(
        max_length=32, blank=True, choices=[(r, r) for r in REJECTION_REASONS]
    )
    story_types = models.JSONField(default=list, blank=True)
    topics = models.JSONField(default=list, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.decision} by {self.reviewer}"


class ReviewQueueItem(Article):
    """Proxy so the pending queue appears as its own admin section."""

    class Meta:
        proxy = True
        verbose_name = "review queue item"
        verbose_name_plural = "review queue"

from django.db import transaction
from django.db.models import F

from articles.constants import REJECTION_REASONS
from articles.models import Article
from articles.services import transition
from sources.models import Source

from .models import ReviewDecision

S = Article.Status
D = ReviewDecision.Decision


def review_article(
    article: Article,
    reviewer: str,
    decision: str,
    *,
    rejection_reason: str = "",
    story_types: list[str] | None = None,
    topics: list[str] | None = None,
    notes: str = "",
) -> ReviewDecision:
    """Record a human decision and apply it. `approve` approves and publishes."""
    if decision == D.REJECT and rejection_reason not in REJECTION_REASONS:
        raise ValueError(f"rejection_reason must be one of {REJECTION_REASONS}")
    with transaction.atomic():
        if story_types is not None:
            article.story_types = story_types
        if topics is not None:
            article.topics = topics
        article.review_decision = decision
        article.reviewed_by = reviewer
        article.rejection_reason = rejection_reason if decision == D.REJECT else ""
        article.save(
            update_fields=[
                "story_types",
                "topics",
                "review_decision",
                "reviewed_by",
                "rejection_reason",
                "updated_at",
            ]
        )
        if decision == D.APPROVE:
            if article.status != S.APPROVED:
                transition(article, S.APPROVED, actor=reviewer, reason=notes)
            transition(article, S.PUBLISHED, actor=reviewer, reason=notes)
        elif decision == D.REJECT:
            transition(article, S.REJECTED, actor=reviewer, reason=f"{rejection_reason}: {notes}")
        elif decision == D.ARCHIVE:
            transition(article, S.ARCHIVED, actor=reviewer, reason=notes)
        elif decision != D.EDIT:
            raise ValueError(f"unknown decision {decision}")
        if decision != D.EDIT:
            Source.objects.filter(pk=article.source_id).update(
                reviewed_count=F("reviewed_count") + 1
            )
        return ReviewDecision.objects.create(
            article=article,
            reviewer=reviewer,
            decision=decision,
            rejection_reason=article.rejection_reason,
            story_types=article.story_types,
            topics=article.topics,
            notes=notes,
        )

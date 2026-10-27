"""Article status machine. All status changes go through `transition`."""

from django.conf import settings
from django.db import transaction

from .models import Article, ArticleStatusEvent

S = Article.Status

ALLOWED_TRANSITIONS: dict[str, set[str]] = {
    S.DISCOVERED: {S.FILTERED_OUT, S.PENDING_REVIEW, S.APPROVED},
    S.FILTERED_OUT: {S.PENDING_REVIEW},
    S.PENDING_REVIEW: {S.APPROVED, S.REJECTED, S.ARCHIVED},
    S.APPROVED: {S.PUBLISHED, S.REJECTED, S.PENDING_REVIEW, S.ARCHIVED},
    S.REJECTED: {S.PENDING_REVIEW},
    S.PUBLISHED: {S.ARCHIVED, S.FLAGGED},
    S.ARCHIVED: {S.PENDING_REVIEW},
    S.FLAGGED: {S.PENDING_REVIEW, S.ARCHIVED},
}


class InvalidTransition(Exception):
    pass


class PublishBlocked(InvalidTransition):
    pass


def before_publish(article: Article) -> None:
    """Hook: approved status, active source with enough trust, no unresolved flags."""
    if article.status != S.APPROVED:
        raise PublishBlocked(f"article is {article.status}, must be approved")
    source = article.source
    if not source.active:
        raise PublishBlocked(f"source {source.name} is not active")
    if source.trust_score < settings.MIN_PUBLISH_TRUST:
        raise PublishBlocked(
            f"source trust {source.trust_score} is below minimum {settings.MIN_PUBLISH_TRUST}"
        )


def create_status_event(
    article: Article, from_status: str, to_status: str, actor: str, reason: str
):
    return ArticleStatusEvent.objects.create(
        article=article, from_status=from_status, to_status=to_status, actor=actor, reason=reason
    )


def transition(
    article: Article, to_status: str, *, actor: str = "system", reason: str = ""
) -> Article:
    with transaction.atomic():
        locked = Article.objects.select_for_update().select_related("source").get(pk=article.pk)
        if to_status not in ALLOWED_TRANSITIONS.get(locked.status, set()):
            raise InvalidTransition(f"{locked.status} -> {to_status} is not allowed")
        if to_status == S.PUBLISHED:
            before_publish(locked)
        from_status = locked.status
        locked.status = to_status
        locked.save(update_fields=["status", "updated_at"])
        create_status_event(locked, from_status, to_status, actor, reason)
    article.status = locked.status
    article.updated_at = locked.updated_at
    return article

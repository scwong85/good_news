import pytest
from django.utils import timezone

from articles.models import Article, ArticleStatusEvent
from articles.services import InvalidTransition, PublishBlocked, transition
from review.models import ReviewDecision
from review.services import review_article
from sources.models import Source


@pytest.fixture
def article(source):
    return Article.objects.create(
        source=source,
        external_id="1",
        canonical_url="https://example.com/a",
        title="A story",
        published_at=timezone.now(),
        status=Article.Status.PENDING_REVIEW,
    )


def test_valid_transition_records_history(article):
    transition(article, "approved", actor="ed", reason="looks good")
    article.refresh_from_db()
    assert article.status == "approved"
    ev = ArticleStatusEvent.objects.get(article=article)
    assert (ev.from_status, ev.to_status, ev.actor, ev.reason) == (
        "pending_review",
        "approved",
        "ed",
        "looks good",
    )


def test_invalid_transition_rejected(article):
    with pytest.raises(InvalidTransition):
        transition(article, "published")  # must be approved first
    article.refresh_from_db()
    assert article.status == "pending_review" and not ArticleStatusEvent.objects.exists()


def test_publish_requires_active_trusted_source(article, source):
    transition(article, "approved")
    Source.objects.filter(pk=source.pk).update(active=False)
    with pytest.raises(PublishBlocked, match="not active"):
        transition(article, "published")
    Source.objects.filter(pk=source.pk).update(active=True, trust_score=0.2)
    with pytest.raises(PublishBlocked, match="trust"):
        transition(article, "published")
    Source.objects.filter(pk=source.pk).update(trust_score=0.9)
    transition(article, "published")
    article.refresh_from_db()
    assert article.status == "published"


def test_flagged_article_cannot_be_published_directly(article):
    transition(article, "approved")
    transition(article, "published")
    transition(article, "flagged")
    with pytest.raises(InvalidTransition):
        transition(article, "published")
    transition(article, "pending_review")  # must go back through review


def test_review_approve_publishes_and_counts(article, source):
    decision = review_article(article, "ed", "approve", topics=["environment"], notes="ok")
    article.refresh_from_db()
    assert (article.status, article.reviewed_by, article.topics) == (
        "published",
        "ed",
        ["environment"],
    )
    assert decision.decision == "approve"
    assert [e.to_status for e in article.status_events.all()] == ["approved", "published"]
    source.refresh_from_db()
    assert source.reviewed_count == 1


def test_review_reject_requires_valid_reason(article):
    with pytest.raises(ValueError):
        review_article(article, "ed", "reject", rejection_reason="because")
    article.refresh_from_db()
    assert article.status == "pending_review"
    review_article(article, "ed", "reject", rejection_reason="too_trivial")
    article.refresh_from_db()
    assert (article.status, article.rejection_reason) == ("rejected", "too_trivial")
    assert ReviewDecision.objects.get().rejection_reason == "too_trivial"


def test_review_cannot_publish_when_source_blocked(article, source):
    Source.objects.filter(pk=source.pk).update(trust_score=0.1)
    with pytest.raises(PublishBlocked):
        review_article(article, "ed", "approve")
    article.refresh_from_db()
    assert article.status == "pending_review"  # whole review rolled back
    assert not ReviewDecision.objects.exists()


def test_edit_keeps_status_and_does_not_count_as_review(article, source):
    review_article(article, "ed", "edit", topics=["health"])
    article.refresh_from_db()
    assert article.status == "pending_review" and article.topics == ["health"]
    source.refresh_from_db()
    assert source.reviewed_count == 0

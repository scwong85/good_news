import pytest
from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.urls import reverse
from django.utils import timezone

from articles.models import Article
from sources.models import Source


def make_article(source, n, status, **kw):
    return Article.objects.create(
        source=source,
        external_id=str(n),
        canonical_url=f"https://example.com/{n}",
        title=f"Story {n}",
        excerpt="Short excerpt",
        published_at=timezone.now(),
        status=status,
        **kw,
    )


def test_feed_shows_only_published(client, source):
    make_article(source, 1, "published", topics=["environment"])
    make_article(source, 2, "pending_review")
    make_article(source, 3, "flagged")
    make_article(source, 4, "rejected")
    html = client.get("/").content.decode()
    assert "Story 1" in html
    for hidden in ("Story 2", "Story 3", "Story 4"):
        assert hidden not in html
    # source, link, topic and date are all shown
    assert (
        "Test Source" in html and 'href="https://example.com/1"' in html and "environment" in html
    )


def test_feed_empty_state(client, db):
    assert "No stories have been published yet" in client.get("/").content.decode()


def test_api_lists_only_published_without_full_text(client, source):
    a = make_article(source, 1, "published")
    make_article(source, 2, "pending_review")
    data = client.get("/api/v1/articles").json()
    assert [r["title"] for r in data["results"]] == ["Story 1"]
    assert (
        "content" not in data["results"][0]
        and data["results"][0]["source"]["name"] == "Test Source"
    )
    assert client.get(f"/api/v1/articles/{a.id}").status_code == 200


def test_api_hides_unpublished_detail(client, source):
    a = make_article(source, 2, "flagged")
    assert client.get(f"/api/v1/articles/{a.id}").status_code == 404


def test_health_endpoint(client, db):
    assert client.get("/api/v1/health").json() == {"status": "ok", "last_ingestion": None}


@pytest.fixture
def staff_client(client, db):
    user = get_user_model().objects.create_superuser("editor", "e@example.com", "pw")
    client.force_login(user)
    return client


def test_review_queue_lists_only_pending(staff_client, source):
    make_article(source, 1, "pending_review")
    make_article(source, 2, "published")
    html = staff_client.get(reverse("admin:review_reviewqueueitem_changelist")).content.decode()
    assert "Story 1" in html and "Story 2" not in html


def test_admin_approve_action_publishes(staff_client, source):
    a = make_article(source, 1, "pending_review")
    resp = staff_client.post(
        reverse("admin:review_reviewqueueitem_changelist"),
        {"action": "approve_and_publish", "_selected_action": [str(a.pk)]},
        follow=True,
    )
    assert resp.status_code == 200
    a.refresh_from_db()
    assert (a.status, a.reviewed_by) == ("published", "editor")


def test_admin_reject_action_records_reason(staff_client, source):
    a = make_article(source, 1, "pending_review")
    staff_client.post(
        reverse("admin:review_reviewqueueitem_changelist"),
        {"action": "reject_promotional", "_selected_action": [str(a.pk)]},
        follow=True,
    )
    a.refresh_from_db()
    assert (a.status, a.rejection_reason) == ("rejected", "promotional")


def test_admin_pages_render(staff_client, source):
    make_article(source, 1, "pending_review")
    for name in (
        "admin:sources_source_changelist",
        "admin:articles_article_changelist",
        "admin:ingestion_ingestionrun_changelist",
        "admin:review_reviewdecision_changelist",
    ):
        assert staff_client.get(reverse(name)).status_code == 200


def test_seed_sources_is_idempotent(db):
    call_command("seed_sources")
    count = Source.objects.count()
    call_command("seed_sources")
    assert Source.objects.count() == count >= 10
    assert Source.objects.filter(active=True).count() >= 10
    assert Source.objects.get(name="Squirrel News").active is False
    assert all(s.licensing_notes for s in Source.objects.filter(active=True))

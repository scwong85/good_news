import httpx
import pytest
import respx

from sources.models import Source


@pytest.fixture(autouse=True)
def _fast_settings(settings):
    settings.FETCH_RETRY_BACKOFF_SECONDS = 0
    settings.CELERY_TASK_ALWAYS_EAGER = True


@pytest.fixture
def source(db):
    return Source.objects.create(
        name="Test Source",
        homepage_url="https://example.com",
        rss_url="https://example.com/feed/",
        tier=1,
        trust_score=0.9,
        language="en",
        regions=["global"],
        active=True,
        licensing_notes="headline + short excerpt + link only",
    )


@pytest.fixture
def mock_web():
    """HTTP mock with a permissive robots.txt; each test adds its feed route."""
    with respx.mock(assert_all_called=False) as router:
        router.get("https://example.com/robots.txt").mock(
            return_value=httpx.Response(200, text="User-agent: *\nAllow: /\n")
        )
        yield router

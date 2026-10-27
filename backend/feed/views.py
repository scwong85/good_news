from django.shortcuts import render

from .api_views import published_articles


def index(request):
    """Minimal server-rendered feed of published (approved) stories."""
    return render(request, "feed/index.html", {"articles": published_articles()[:100]})

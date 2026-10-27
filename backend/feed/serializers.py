from rest_framework import serializers

from articles.models import Article
from sources.models import Source


class SourceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Source
        fields = ("id", "name", "homepage_url")


class ArticleSerializer(serializers.ModelSerializer):
    """Public shape (docs/api-contracts.md). Never includes full article text."""

    source = SourceSerializer(read_only=True)

    class Meta:
        model = Article
        fields = (
            "id",
            "title",
            "excerpt",
            "summary",
            "why_it_matters",
            "source",
            "canonical_url",
            "published_at",
            "topics",
            "regions",
            "story_types",
            "evidence_signals",
        )

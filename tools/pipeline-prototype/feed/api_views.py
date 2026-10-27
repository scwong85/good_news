from rest_framework import generics
from rest_framework.decorators import api_view
from rest_framework.response import Response

from articles.models import Article
from ingestion.models import IngestionRun

from .serializers import ArticleSerializer


def published_articles():
    return Article.objects.filter(status=Article.Status.PUBLISHED).select_related("source")


class ArticleList(generics.ListAPIView):
    serializer_class = ArticleSerializer

    def get_queryset(self):
        qs = published_articles()
        topic = self.request.query_params.get("topic")
        if topic:
            qs = qs.filter(topics__contains=[topic])
        return qs

    # CursorPagination needs an explicit ordering field
    ordering = "-published_at"

    def paginate_queryset(self, queryset):
        self.paginator.ordering = "-published_at"
        return super().paginate_queryset(queryset)


class ArticleDetail(generics.RetrieveAPIView):
    serializer_class = ArticleSerializer

    def get_queryset(self):
        return published_articles()


@api_view(["GET"])
def health(request):
    run = (
        IngestionRun.objects.exclude(status=IngestionRun.Status.SKIPPED)
        .order_by("-started_at")
        .first()
    )
    return Response(
        {
            "status": "ok",
            "last_ingestion": run
            and {
                "source": run.source.name,
                "status": run.status,
                "finished_at": run.finished_at,
            },
        }
    )

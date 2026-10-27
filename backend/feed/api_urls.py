from django.urls import path

from . import api_views

urlpatterns = [
    path("health", api_views.health, name="api-health"),
    path("articles", api_views.ArticleList.as_view(), name="api-articles"),
    path("articles/<uuid:pk>", api_views.ArticleDetail.as_view(), name="api-article"),
]

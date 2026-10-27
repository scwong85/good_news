from django.contrib import admin

from .models import Article, ArticleStatusEvent


class StatusEventInline(admin.TabularInline):
    model = ArticleStatusEvent
    extra = 0
    can_delete = False
    readonly_fields = ("from_status", "to_status", "actor", "reason", "created_at")

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    list_display = ("title", "source", "status", "published_at", "constructive_score")
    list_filter = ("status", "source", "source__tier")
    search_fields = ("title", "canonical_url")
    date_hierarchy = "published_at"
    readonly_fields = (
        "source",
        "raw_item",
        "external_id",
        "canonical_url",
        "status",
        "classification_explanation",
        "created_at",
        "updated_at",
    )
    inlines = [StatusEventInline]

from django.contrib import admin, messages

from .models import Source


@admin.register(Source)
class SourceAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "tier",
        "trust_score",
        "active",
        "fetch_interval_minutes",
        "last_fetched_at",
        "last_run_status",
    )
    list_filter = ("active", "tier", "language")
    list_editable = ("trust_score", "active")
    search_fields = ("name", "homepage_url", "rss_url")
    readonly_fields = ("last_fetched_at", "etag", "last_modified", "reviewed_count")
    actions = ["fetch_now", "enable", "disable"]

    @admin.display(description="Last run")
    def last_run_status(self, obj):
        run = obj.ingestion_runs.order_by("-started_at").first()
        return run.status if run else "-"

    @admin.action(description="Fetch selected sources now (ignores interval)")
    def fetch_now(self, request, queryset):
        from ingestion.service import ingest_source

        for source in queryset:
            run = ingest_source(source, force=True)
            level = messages.SUCCESS if run.status in {"success", "partial"} else messages.WARNING
            self.message_user(
                request,
                f"{source.name}: {run.status} (created {run.items_created}, "
                f"skipped {run.items_skipped}) {run.error_message}",
                level,
            )

    @admin.action(description="Enable selected sources")
    def enable(self, request, queryset):
        queryset.update(active=True)

    @admin.action(description="Disable selected sources (stops future ingestion)")
    def disable(self, request, queryset):
        queryset.update(active=False)

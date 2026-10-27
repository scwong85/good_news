from django.contrib import admin

from .models import IngestionRun, RawItem


@admin.register(IngestionRun)
class IngestionRunAdmin(admin.ModelAdmin):
    list_display = (
        "source",
        "status",
        "started_at",
        "http_status",
        "items_seen",
        "items_created",
        "items_skipped",
        "items_failed",
    )
    list_filter = ("status", "source")
    readonly_fields = [f.name for f in IngestionRun._meta.fields]

    def has_add_permission(self, request):
        return False


@admin.register(RawItem)
class RawItemAdmin(admin.ModelAdmin):
    list_display = ("source", "external_id", "fetched_at")
    list_filter = ("source",)
    search_fields = ("external_id",)
    readonly_fields = [f.name for f in RawItem._meta.fields]

    def has_add_permission(self, request):
        return False

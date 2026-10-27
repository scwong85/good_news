from django.contrib import admin, messages

from articles.constants import REJECTION_REASONS
from articles.models import Article
from articles.services import InvalidTransition

from .models import ReviewDecision, ReviewQueueItem
from .services import review_article


def _make_reject_action(reason: str):
    @admin.action(description=f"Reject: {reason}")
    def action(modeladmin, request, queryset):
        modeladmin._apply(request, queryset, "reject", rejection_reason=reason)

    action.__name__ = f"reject_{reason}"
    return action


@admin.register(ReviewQueueItem)
class ReviewQueueAdmin(admin.ModelAdmin):
    list_display = ("title", "source", "published_at", "topics", "constructive_score")
    list_filter = ("source", "source__tier")
    search_fields = ("title", "canonical_url")
    ordering = ("-published_at",)
    fields = (
        "title",
        "excerpt",
        "canonical_url",
        "source",
        "published_at",
        "topics",
        "story_types",
    )
    readonly_fields = ("canonical_url", "source", "published_at")
    actions = ["approve_and_publish", "archive"] + [
        _make_reject_action(r) for r in REJECTION_REASONS
    ]

    def get_queryset(self, request):
        return super().get_queryset(request).filter(status=Article.Status.PENDING_REVIEW)

    def has_add_permission(self, request):
        return False

    def _apply(self, request, queryset, decision, **kwargs):
        done = failed = 0
        for article in queryset:
            try:
                review_article(article, request.user.get_username(), decision, **kwargs)
                done += 1
            except (InvalidTransition, ValueError) as exc:
                failed += 1
                self.message_user(request, f"{article.title[:60]}: {exc}", messages.ERROR)
        if done:
            self.message_user(request, f"{done} article(s): {decision}", messages.SUCCESS)

    @admin.action(description="Approve and publish")
    def approve_and_publish(self, request, queryset):
        self._apply(request, queryset, "approve")

    @admin.action(description="Archive")
    def archive(self, request, queryset):
        self._apply(request, queryset, "archive")

    def save_model(self, request, obj, form, change):
        super().save_model(request, obj, form, change)
        if change and form.changed_data:
            review_article(obj, request.user.get_username(), "edit", notes="edited in admin")
            # `edit` records the decision without changing status.


@admin.register(ReviewDecision)
class ReviewDecisionAdmin(admin.ModelAdmin):
    list_display = ("article", "decision", "rejection_reason", "reviewer", "created_at")
    list_filter = ("decision", "rejection_reason", "reviewer")
    readonly_fields = [f.name for f in ReviewDecision._meta.fields]

    def has_add_permission(self, request):
        return False

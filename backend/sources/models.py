import uuid

from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class Source(models.Model):
    class Tier(models.IntegerChoices):
        DEDICATED = 1, "Tier 1: dedicated constructive-news outlet"
        TOPIC = 2, "Tier 2: reputable topic feed"
        DISCOVERY = 3, "Tier 3: broad discovery (always reviewed)"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200, unique=True)
    homepage_url = models.URLField(max_length=500)
    rss_url = models.URLField(max_length=500, unique=True)
    tier = models.PositiveSmallIntegerField(choices=Tier.choices, default=Tier.DEDICATED)
    trust_score = models.FloatField(
        default=0.5, validators=[MinValueValidator(0.0), MaxValueValidator(1.0)]
    )
    language = models.CharField(max_length=8, default="en")
    regions = models.JSONField(default=list, blank=True)
    active = models.BooleanField(default=False)
    fetch_interval_minutes = models.PositiveIntegerField(default=60)
    robots_policy = models.CharField(
        max_length=16, choices=[("respect", "Respect robots.txt")], default="respect"
    )
    licensing_notes = models.TextField(blank=True)
    # Counts human-reviewed articles; the first 100 from a new source always need review.
    reviewed_count = models.PositiveIntegerField(default=0)
    # Fetch bookkeeping
    last_fetched_at = models.DateTimeField(null=True, blank=True)
    etag = models.CharField(max_length=500, blank=True)
    last_modified = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["tier", "name"]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(trust_score__gte=0, trust_score__lte=1),
                name="source_trust_score_between_0_and_1",
            ),
            models.CheckConstraint(
                condition=models.Q(tier__gte=1, tier__lte=3), name="source_tier_between_1_and_3"
            ),
        ]

    def __str__(self) -> str:
        return self.name

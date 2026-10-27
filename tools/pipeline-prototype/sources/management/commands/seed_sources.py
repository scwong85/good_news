import csv
from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from sources.models import Source

DEFAULT_CSV = settings.REPO_ROOT / "docs" / "source-allowlist.csv"


class Command(BaseCommand):
    help = "Create or update Sources from docs/source-allowlist.csv (idempotent)."

    def add_arguments(self, parser):
        parser.add_argument("--csv", default=str(DEFAULT_CSV))

    def handle(self, *args, **options):
        path = Path(options["csv"])
        if not path.exists():
            raise CommandError(f"{path} not found")
        created = updated = 0
        with path.open(newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                _, was_created = Source.objects.update_or_create(
                    name=row["name"],
                    defaults={
                        "homepage_url": row["homepage_url"],
                        "rss_url": row["rss_url"],
                        "tier": int(row["tier"]),
                        "trust_score": float(row["trust_score"]),
                        "language": row["language"],
                        "regions": [r for r in row["regions"].split(";") if r],
                        "active": row["active"].strip().lower() == "true",
                        "fetch_interval_minutes": int(row["fetch_interval_minutes"]),
                        "robots_policy": row["robots_policy"],
                        "licensing_notes": row["licensing_notes"],
                    },
                )
                created += was_created
                updated += not was_created
        self.stdout.write(self.style.SUCCESS(f"Sources: {created} created, {updated} updated"))

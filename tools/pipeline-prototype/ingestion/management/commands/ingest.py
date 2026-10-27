from django.core.management.base import BaseCommand, CommandError

from ingestion.fetch import make_client
from ingestion.service import ingest_source
from sources.models import Source


class Command(BaseCommand):
    help = "Fetch RSS feeds now. Safe to rerun (no duplicate canonical URLs)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--source", action="append", help="Source name (repeatable). Default: all active."
        )
        parser.add_argument("--force", action="store_true", help="Ignore fetch interval and ETag.")
        parser.add_argument("--backfill-pages", type=int, default=1, help="Also fetch ?paged=2..N.")
        parser.add_argument(
            "--max-age-days",
            type=int,
            default=None,
            help="Age filter; 0 disables (default: setting).",
        )

    def handle(self, *args, **opts):
        qs = Source.objects.filter(active=True)
        if opts["source"]:
            qs = Source.objects.filter(name__in=opts["source"])
            missing = set(opts["source"]) - set(qs.values_list("name", flat=True))
            if missing:
                raise CommandError(f"unknown source(s): {', '.join(sorted(missing))}")
        total_created = 0
        with make_client() as client:
            robots_cache: dict = {}
            for source in qs:
                for page in range(1, opts["backfill_pages"] + 1):
                    run = ingest_source(
                        source,
                        force=opts["force"] or page > 1,
                        page=page,
                        max_age_days=opts["max_age_days"],
                        client=client,
                        robots_cache=robots_cache,
                    )
                    total_created += run.items_created
                    self.stdout.write(
                        f"{source.name} p{page}: {run.status} seen={run.items_seen} "
                        f"created={run.items_created} skipped={run.items_skipped} "
                        f"failed={run.items_failed} {run.error_message}"
                    )
                    if run.status != "success" or run.items_created == 0:
                        break
        self.stdout.write(self.style.SUCCESS(f"Total new articles: {total_created}"))

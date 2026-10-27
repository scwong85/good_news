import 'dart:async';
import 'dart:math' as math;

import '../data/db/app_database.dart';
import '../data/http/feed_fetcher.dart';
import '../classification/classification_service.dart';
import '../data/sources/story_source.dart';
import '../domain/source.dart' as domain;
import '../pipeline/feed_parser.dart';

enum SourceStatus { ok, notModified, skippedFresh, skippedBackoff, failed, deadline }

class SourceOutcome {
  SourceOutcome(this.sourceId, this.status,
      {this.itemsSeen = 0, this.itemsNew = 0, this.itemsSkipped = 0, this.error});
  final String sourceId;
  final SourceStatus status;
  final int itemsSeen;
  final int itemsNew;
  final int itemsSkipped;
  final String? error;
}

class IngestionReport {
  IngestionReport(this.outcomes, this.startedAt, this.finishedAt);
  final List<SourceOutcome> outcomes;
  final DateTime startedAt;
  final DateTime finishedAt;

  int get totalNew => outcomes.fold(0, (sum, o) => sum + o.itemsNew);
  int get failed => outcomes.where((o) => o.status == SourceStatus.failed).length;
  SourceOutcome? outcomeFor(String id) {
    for (final o in outcomes) {
      if (o.sourceId == id) return o;
    }
    return null;
  }
}

/// Fetch-on-open pipeline (docs/architecture.md): refresh all enabled sources in parallel,
/// isolate failures, store new articles idempotently.
class IngestionService {
  IngestionService({
    required this.db,
    required this.storySource,
    DateTime Function()? now,
    this.ttl = const Duration(minutes: 30),
    this.concurrency = 4,
    this.deadline = const Duration(seconds: 15),
    this.retentionDays = 30,
    this.classification,
    this.afterRefresh = const [],
  }) : _now = now ?? DateTime.now;

  final AppDatabase db;
  final StorySource storySource;
  final DateTime Function() _now;
  final Duration ttl;
  final int concurrency;
  final Duration deadline;
  final int retentionDays;

  /// When set, new articles are classified on insert (`after_classify`).
  final ClassificationService? classification;

  /// Run in order after all sources finished (re-classification after a rules update,
  /// duplicate clustering, ...). A failing hook never fails the refresh.
  final List<Future<Object?> Function()> afterRefresh;

  /// Refreshes every enabled source. [force] ignores the cache TTL, backoff and ETags.
  Future<IngestionReport> refresh({bool force = false}) async {
    final startedAt = _now().toUtc();
    final sources = await db.enabledSources();
    final outcomes = <String, SourceOutcome>{};
    final queue = <SourceRow>[];

    for (final s in sources) {
      final skip = _beforeFetch(s, startedAt, force);
      if (skip != null) {
        outcomes[s.id] = SourceOutcome(s.id, skip);
      } else {
        queue.add(s);
      }
    }

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final source = queue.removeAt(0);
        outcomes[source.id] = await _refreshOne(source, force);
      }
    }

    final workers = List.generate(math.min(concurrency, math.max(queue.length, 1)), (_) => worker());
    try {
      await Future.wait(workers).timeout(deadline);
    } on TimeoutException {
      queue.clear(); // sources not started in time are reported as deadline
      for (final s in sources) {
        outcomes.putIfAbsent(s.id, () => SourceOutcome(s.id, SourceStatus.deadline, error: 'deadline'));
      }
    }
    for (final s in sources) {
      outcomes.putIfAbsent(s.id, () => SourceOutcome(s.id, SourceStatus.deadline, error: 'deadline'));
    }

    await db.pruneArticles(startedAt.subtract(Duration(days: retentionDays)));
    for (final hook in afterRefresh) {
      try {
        await hook();
      } catch (_) {
        // Hooks are best-effort; the refresh result stands.
      }
    }
    return IngestionReport(
      sources.map((s) => outcomes[s.id]!).toList(),
      startedAt,
      _now().toUtc(),
    );
  }

  /// `before_fetch` hook: enabled (already filtered), not in backoff, cache older than TTL.
  SourceStatus? _beforeFetch(SourceRow s, DateTime now, bool force) {
    if (force) return null;
    if (s.backoffUntil != null && s.backoffUntil!.isAfter(now)) return SourceStatus.skippedBackoff;
    if (s.lastFetchedAt != null && now.difference(s.lastFetchedAt!) < ttl) {
      return SourceStatus.skippedFresh;
    }
    return null;
  }

  Future<SourceOutcome> _refreshOne(SourceRow row, bool force) async {
    final source = domain.Source(
      id: row.id,
      name: row.name,
      homepageUrl: row.homepageUrl,
      rssUrl: row.rssUrl,
      tier: row.tier,
      trustScore: row.trustScore,
      language: row.language,
      regions: row.regions,
    );
    try {
      final result = await storySource.load(
        source,
        previous: force ? const FetchState() : FetchState(etag: row.etag, lastModified: row.lastModified),
      );
      final now = _now().toUtc();
      final cutoff = now.subtract(Duration(days: retentionDays));
      final fresh = result.candidates.map((c) => c.item).where((i) => !i.publishedAt.isBefore(cutoff)).toList();
      final classifications = {
        if (classification != null)
          for (final item in fresh) item.canonicalUrl: classification!.classifyNew(item, row),
      };
      final added = await db.insertNewArticles(source.id, fresh, now, classifications: classifications);
      await db.recordFetchSuccess(
        source.id,
        at: now,
        etag: result.etag,
        lastModified: result.lastModified,
        status: result.notModified ? 'not_modified' : 'ok',
      );
      return SourceOutcome(
        source.id,
        result.notModified ? SourceStatus.notModified : SourceStatus.ok,
        itemsSeen: result.itemsSeen,
        itemsNew: added,
        itemsSkipped: result.itemsSkipped + (result.candidates.length - fresh.length),
      );
    } on FetchFailure catch (e) {
      return _failed(row, e.message, retryAfter: e.retryAfter);
    } on FeedParseException catch (e) {
      return _failed(row, e.message);
    } catch (e) {
      return _failed(row, 'unexpected error: ${e.runtimeType}');
    }
  }

  /// `after_fetch` hook for failures. A 429 with Retry-After backs the source off for that long;
  /// otherwise backoff starts after 3 consecutive failures (15 min doubling, capped at 6 h).
  Future<SourceOutcome> _failed(SourceRow row, String message, {Duration? retryAfter}) async {
    final failures = row.consecutiveFailures + 1;
    final now = _now().toUtc();
    Duration? backoff = retryAfter;
    if (backoff == null && failures >= 3) {
      final minutes = math.min(15 * math.pow(2, failures - 3).toInt(), 360);
      backoff = Duration(minutes: minutes);
    }
    await db.recordFetchFailure(
      row.id,
      status: 'error: $message',
      failures: failures,
      backoffUntil: backoff == null ? null : now.add(backoff),
    );
    return SourceOutcome(row.id, SourceStatus.failed, error: message);
  }
}

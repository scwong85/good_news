import '../data/db/app_database.dart';
import 'daily_selector.dart';
import 'preferences.dart';

/// Creates and returns the day's picks (`before_select` hook: drops hidden, seen and
/// out-of-window stories and respects the enabled sources; see [selectPicks]).
///
/// Picks are persisted per local calendar day, so they are stable all day; raising
/// stories_per_day appends the next best stories.
class DailyPicksService {
  DailyPicksService(
    this.db,
    this.preferences, {
    DateTime Function()? now,
    this.config = const SelectorConfig(),
  }) : _now = now ?? DateTime.now;

  final AppDatabase db;
  final PreferencesRepository preferences;
  final DateTime Function() _now;
  final SelectorConfig config;

  /// `yyyy-MM-dd` of the device's local calendar day.
  static String dayKey(DateTime now) {
    final l = now.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)}';
  }

  /// Today's already-created picks (limited to stories_per_day) without creating or extending
  /// anything. Used to show the cache instantly on launch; the day's picks are created only after
  /// the fresh fetch, so that today's news can be part of them.
  Future<List<ArticleRow>> existingPicks() async {
    final prefs = await preferences.load();
    final picks = await db.picksForDay(dayKey(_now()));
    return db.articlesByIds(picks.take(prefs.storiesPerDay).map((p) => p.articleId).toList());
  }

  Future<void> _queue = Future.value();

  /// Runs [task] after all earlier tasks finished, so that picks are never created from stale
  /// data by two overlapping calls (a fast slider drag or a refresh racing a settings change).
  Future<T> _serialized<T>(Future<T> Function() task) {
    final run = _queue.then((_) => task());
    _queue = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  /// Today's picks, creating or extending them if needed, limited to stories_per_day.
  /// Calls are serialized and idempotent.
  Future<List<ArticleRow>> todaysPicks() => _serialized(_todaysPicks);

  Future<List<ArticleRow>> _todaysPicks() async {
    final now = _now().toUtc();
    final day = dayKey(_now());
    final prefs = await preferences.load();
    var picks = await db.picksForDay(day);

    if (picks.length < prefs.storiesPerDay) {
      final cutoff = now.subtract(Duration(days: config.ageWindowDays));
      final rows = await db.pickCandidates(cutoff);
      // Stories opened before, or picked on an earlier day, never come back.
      final seen = {...await db.seenIds(), ...await db.pickedArticleIdsExceptDay(day)};
      final byId = {for (final (a, _) in rows) a.id: a};
      final candidates = [for (final (a, s) in rows) _toCandidate(a, s.trustScore, seen.contains(a.id))];
      final existing = [
        for (final p in picks)
          if (byId[p.articleId] != null)
            _toCandidate(byId[p.articleId]!, 0, false)
          else
            // A pick whose article is gone/ineligible still counts toward the quota.
            PickCandidate(
              id: p.articleId,
              sourceId: '',
              route: '',
              trustScore: 0,
              constructiveScore: 0,
              publishedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              topics: const [],
            ),
      ];
      final seenClusters = {
        for (final c in candidates)
          if (c.seen) c.clusterKey,
      };
      final add = selectPicks(
        candidates: candidates,
        existing: existing,
        target: prefs.storiesPerDay,
        now: now,
        preferredTopics: prefs.topics,
        seenClusterKeys: seenClusters,
        config: config,
      );
      await db.appendPicks(day, add);
      picks = await db.picksForDay(day);
    }
    final shown = picks.take(prefs.storiesPerDay).map((p) => p.articleId).toList();
    return db.articlesByIds(shown);
  }

  Future<void> markSeen(Iterable<String> articleIds) => db.markSeen(articleIds, _now().toUtc());
}

PickCandidate _toCandidate(ArticleRow a, double trust, bool seen) => PickCandidate(
      id: a.id,
      sourceId: a.sourceId,
      route: a.route ?? '',
      trustScore: trust,
      constructiveScore: a.constructiveScore ?? 0,
      publishedAt: a.publishedAt,
      topics: a.topics,
      clusterId: a.clusterId,
      seen: seen,
      hidden: a.hidden,
    );

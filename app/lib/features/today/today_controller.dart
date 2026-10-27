import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/providers.dart';
import '../../ingestion/ingestion_service.dart';
import '../shared/story.dart';

/// What went wrong during the last refresh, in reader terms.
enum RefreshIssue { none, offline, partial, failed }

class TodayState {
  const TodayState({
    this.picks = const [],
    this.loading = true,
    this.refreshing = false,
    this.lastUpdated,
    this.issue = RefreshIssue.none,
    this.failedSources = 0,
    this.totalSources = 0,
  });

  final List<Story> picks;

  /// True until the first picks (cached or fresh) are known.
  final bool loading;
  final bool refreshing;
  final DateTime? lastUpdated;
  final RefreshIssue issue;
  final int failedSources;
  final int totalSources;

  TodayState copyWith({
    List<Story>? picks,
    bool? loading,
    bool? refreshing,
    DateTime? lastUpdated,
    RefreshIssue? issue,
    int? failedSources,
    int? totalSources,
  }) =>
      TodayState(
        picks: picks ?? this.picks,
        loading: loading ?? this.loading,
        refreshing: refreshing ?? this.refreshing,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        issue: issue ?? this.issue,
        failedSources: failedSources ?? this.failedSources,
        totalSources: totalSources ?? this.totalSources,
      );
}

/// Fetch-on-open for the Today screen (docs/architecture.md):
///  1. show today's already-created picks from the cache immediately;
///  2. refresh the feeds (parallel, 15 s deadline);
///  3. only then create or extend today's picks, so today's news can be part of them.
/// If there are no picks yet today, the screen shows a loading state until step 3.
class TodayController extends Notifier<TodayState> {
  static const _minForceGap = Duration(minutes: 2);
  DateTime? _lastForced;
  bool _started = false;

  @override
  TodayState build() {
    Future.microtask(start);
    return const TodayState();
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      await ref.read(databaseProvider).upsertBundledSources(await ref.read(bundledSourcesProvider.future));
      final cached = await ref.read(storyRepositoryProvider).fromArticles(
            await ref.read(dailyPicksServiceProvider).existingPicks(),
          );
      state = state.copyWith(
        picks: cached,
        loading: cached.isEmpty,
        lastUpdated: await _lastFetched(),
      );
    } catch (_) {
      // Fall through: the refresh below reports problems to the reader.
    }
    await refresh();
  }

  /// [manual]: the reader pulled to refresh. A manual refresh bypasses the 30 minute cache at
  /// most once every two minutes (being a polite client matters more than instant refreshes).
  Future<void> refresh({bool manual = false}) async {
    if (state.refreshing) return;
    state = state.copyWith(refreshing: true);
    final now = ref.read(clockProvider)();
    final force = manual && (_lastForced == null || now.difference(_lastForced!) >= _minForceGap);
    if (force) _lastForced = now;
    try {
      final service = await ref.read(ingestionServiceProvider.future);
      final report = await service.refresh(force: force);
      final issue = _issueFor(report);
      final rows = await ref.read(dailyPicksServiceProvider).todaysPicks();
      final picks = await ref.read(storyRepositoryProvider).fromArticles(rows);
      state = TodayState(
        picks: picks,
        loading: false,
        refreshing: false,
        lastUpdated: await _lastFetched() ?? state.lastUpdated,
        issue: issue.$1,
        failedSources: issue.$2,
        totalSources: report.outcomes.length,
      );
    } catch (_) {
      state = state.copyWith(refreshing: false, loading: false, issue: RefreshIssue.failed);
    }
    ref.read(dataVersionProvider.notifier).bump();
  }

  /// Re-reads the day's picks after a setting changed; [extend] also adds stories when the
  /// reader raised stories per day.
  Future<void> reloadPicks({bool extend = false}) async {
    final service = ref.read(dailyPicksServiceProvider);
    final rows = extend ? await service.todaysPicks() : await service.existingPicks();
    final picks = await ref.read(storyRepositoryProvider).fromArticles(rows);
    state = state.copyWith(picks: picks, loading: false);
  }

  Future<DateTime?> _lastFetched() async {
    DateTime? latest;
    for (final s in await ref.read(databaseProvider).allSources()) {
      final t = s.lastFetchedAt;
      if (t != null && (latest == null || t.isAfter(latest))) latest = t;
    }
    return latest;
  }

  (RefreshIssue, int) _issueFor(IngestionReport report) {
    final attempted = report.outcomes
        .where((o) => o.status != SourceStatus.skippedFresh && o.status != SourceStatus.skippedBackoff)
        .toList();
    final failed = attempted.where((o) => o.status == SourceStatus.failed || o.status == SourceStatus.deadline).length;
    if (attempted.isEmpty || failed == 0) return (RefreshIssue.none, 0);
    if (failed == attempted.length) return (RefreshIssue.offline, failed);
    return (RefreshIssue.partial, failed);
  }
}

final todayControllerProvider = NotifierProvider<TodayController, TodayState>(TodayController.new);

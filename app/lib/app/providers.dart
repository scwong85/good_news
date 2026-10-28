import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../data/story_repository.dart';
import '../selection/feedback_service.dart';
import '../selection/preferences.dart';
import '../features/shared/story.dart';
import 'platform_services.dart';

/// The clock the UI uses for labels like "Updated 5 min ago" (overridden in tests).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final linkOpenerProvider = Provider<LinkOpener>((ref) => const UrlLauncherLinkOpener());
final sharerProvider = Provider<Sharer>((ref) => const SharePlusSharer());

final storyRepositoryProvider = Provider<StoryRepository>(
  (ref) => StoryRepository(ref.watch(databaseProvider), now: ref.watch(clockProvider)),
);

/// Bumped whenever stored data the lists depend on changes (a refresh, saving a story, a
/// setting), so dependent providers reload.
class DataVersion extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final dataVersionProvider = NotifierProvider<DataVersion, int>(DataVersion.new);

final savedIdsProvider = FutureProvider<Set<String>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(databaseProvider).bookmarkedIds();
});

final savedStoriesProvider = FutureProvider<List<Story>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(storyRepositoryProvider).saved();
});

final storyProvider = FutureProvider.family<Story?, String>((ref, id) {
  ref.watch(dataVersionProvider);
  return ref.watch(storyRepositoryProvider).byId(id);
});

final preferencesProvider = FutureProvider<Preferences>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(preferencesRepositoryProvider).load();
});

final sourcesProvider = FutureProvider((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(databaseProvider).allSources();
});

final feedbackServiceProvider = Provider<FeedbackService>((ref) => FeedbackService(ref.watch(databaseProvider)));

/// Stories the reader hid, newest first.
final hiddenStoriesProvider = FutureProvider<List<Story>>((ref) async {
  ref.watch(dataVersionProvider);
  final rows = await ref.watch(databaseProvider).hiddenArticles();
  return [for (final (a, s) in rows) Story.fromRows(a, s)];
});

final regionsProvider = FutureProvider<List<String>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(storyRepositoryProvider).availableRegions();
});

/// Explore filters.
class ExploreQueryNotifier extends Notifier<ExploreQuery> {
  @override
  ExploreQuery build() => const ExploreQuery();

  void setText(String text) => state = state.copyWith(text: text);
  void toggleTopic(String t) => state = state.copyWith(topics: _toggle(state.topics, t));
  void toggleRegion(String r) => state = state.copyWith(regions: _toggle(state.regions, r));
  void toggleType(String t) => state = state.copyWith(storyTypes: _toggle(state.storyTypes, t));
  void clear() => state = const ExploreQuery();

  Set<String> _toggle(Set<String> s, String v) => s.contains(v) ? ({...s}..remove(v)) : {...s, v};
}

final exploreQueryProvider = NotifierProvider<ExploreQueryNotifier, ExploreQuery>(ExploreQueryNotifier.new);

final exploreResultsProvider = FutureProvider<List<Story>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(storyRepositoryProvider).explore(ref.watch(exploreQueryProvider));
});

/// Save / unsave, then reload anything that shows saved state.
class StoryActions {
  StoryActions(this._ref);
  final Ref _ref;

  Future<void> toggleSaved(Story story, {required bool isSaved}) async {
    final repo = _ref.read(storyRepositoryProvider);
    if (isSaved) {
      await repo.unsave(story.id);
    } else {
      await repo.save(story);
    }
    _ref.read(dataVersionProvider.notifier).bump();
  }

  /// Best effort: failing to note that a story was seen must never get in the reader's way.
  Future<void> markSeen(String id) async {
    try {
      await _ref.read(storyRepositoryProvider).markSeen(id);
    } catch (_) {}
  }
}

final storyActionsProvider = Provider<StoryActions>(StoryActions.new);

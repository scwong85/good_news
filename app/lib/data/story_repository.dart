import '../features/shared/story.dart';
import '../pipeline/classifier.dart';
import 'db/app_database.dart';

/// Filters for the Explore screen. All filters are optional; sets match any of their values.
class ExploreQuery {
  const ExploreQuery({
    this.text = '',
    this.topics = const {},
    this.regions = const {},
    this.storyTypes = const {},
  });

  final String text;
  final Set<String> topics;
  final Set<String> regions;
  final Set<String> storyTypes;

  bool get isEmpty => text.trim().isEmpty && topics.isEmpty && regions.isEmpty && storyTypes.isEmpty;

  ExploreQuery copyWith({String? text, Set<String>? topics, Set<String>? regions, Set<String>? storyTypes}) =>
      ExploreQuery(
        text: text ?? this.text,
        topics: topics ?? this.topics,
        regions: regions ?? this.regions,
        storyTypes: storyTypes ?? this.storyTypes,
      );
}

/// Reads stories for the UI from the on-device database.
class StoryRepository {
  StoryRepository(this.db, {DateTime Function()? now, this.exploreWindowDays = 14, this.exploreLimit = 200})
      : _now = now ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _now;
  final int exploreWindowDays;
  final int exploreLimit;

  /// Converts article rows (for example today's picks) into stories, keeping their order.
  Future<List<Story>> fromArticles(List<ArticleRow> rows) async {
    if (rows.isEmpty) return const [];
    final sources = {for (final s in await db.allSources()) s.id: s};
    final saved = await db.bookmarkedIds();
    return [
      for (final a in rows)
        if (sources[a.sourceId] != null) Story.fromRows(a, sources[a.sourceId]!, saved: saved.contains(a.id)),
    ];
  }

  /// Shown-eligible stories of the last [exploreWindowDays] days, newest first, filtered.
  /// Only one story per duplicate cluster (the best scored) is listed.
  Future<List<Story>> explore(ExploreQuery query) async {
    final cutoff = _now().toUtc().subtract(Duration(days: exploreWindowDays));
    final rows = await db.pickCandidates(cutoff);
    final saved = await db.bookmarkedIds();
    final terms = query.text.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    bool matches((ArticleRow, SourceRow) r) {
      final (a, s) = r;
      if (a.route != routeToday && a.route != routeExplore) return false;
      if (query.topics.isNotEmpty && !a.topics.any(query.topics.contains)) return false;
      if (query.regions.isNotEmpty && !a.regions.any(query.regions.contains)) return false;
      if (query.storyTypes.isNotEmpty && !a.storyTypes.any(query.storyTypes.contains)) return false;
      if (terms.isNotEmpty) {
        final hay = '${a.title} ${a.excerpt} ${s.name}'.toLowerCase();
        if (!terms.every(hay.contains)) return false;
      }
      return true;
    }

    final byCluster = <String, (ArticleRow, SourceRow)>{};
    for (final r in rows.where(matches)) {
      final key = r.$1.clusterId ?? r.$1.id;
      final current = byCluster[key];
      if (current == null || _better(r.$1, current.$1)) byCluster[key] = r;
    }
    final list = byCluster.values.toList()
      ..sort((x, y) {
        final t = y.$1.publishedAt.compareTo(x.$1.publishedAt);
        return t != 0 ? t : x.$1.id.compareTo(y.$1.id);
      });
    return [
      for (final (a, s) in list.take(exploreLimit)) Story.fromRows(a, s, saved: saved.contains(a.id)),
    ];
  }

  bool _better(ArticleRow a, ArticleRow b) {
    final s = (a.constructiveScore ?? 0).compareTo(b.constructiveScore ?? 0);
    if (s != 0) return s > 0;
    final t = a.publishedAt.compareTo(b.publishedAt);
    return t != 0 ? t > 0 : a.id.compareTo(b.id) < 0;
  }

  /// A story by id: from the article table, or else from its saved snapshot.
  Future<Story?> byId(String id) async {
    final saved = await db.bookmarkedIds();
    final row = await db.articleWithSource(id);
    if (row != null) return Story.fromRows(row.$1, row.$2, saved: saved.contains(id));
    for (final b in await db.allBookmarks()) {
      if (b.articleId == id) return Story.fromSnapshot(b.snapshot);
    }
    return null;
  }

  /// Saved stories, newest saved first, from their snapshots (works offline, survives pruning).
  Future<List<Story>> saved() async => [
        for (final b in await db.allBookmarks()) Story.fromSnapshot(b.snapshot),
      ];

  Future<void> save(Story story) => db.addBookmark(story.id, story.toSnapshot(), _now().toUtc());
  Future<void> unsave(String id) => db.removeBookmark(id);
  Future<void> markSeen(String id) => db.markSeen([id], _now().toUtc());

  /// Regions present in the enabled sources' stories (the filter is hidden if there is only one).
  Future<List<String>> availableRegions() async {
    final cutoff = _now().toUtc().subtract(Duration(days: exploreWindowDays));
    final regions = <String>{};
    for (final (a, _) in await db.pickCandidates(cutoff)) {
      regions.addAll(a.regions);
    }
    return regions.toList()..sort();
  }
}

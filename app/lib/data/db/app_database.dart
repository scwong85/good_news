import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../domain/source.dart' as domain;
import '../../pipeline/classifier.dart';
import '../../pipeline/normalize.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// First 16 hex characters of sha1(canonicalUrl): the article id.
String articleIdFor(String canonicalUrl) =>
    sha1.convert(utf8.encode(canonicalUrl)).toString().substring(0, 16);

@DriftDatabase(tables: [Sources, Articles, DailyPicks, Seen, PreferenceEntries, Bookmarks])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2 (Phase 4): daily picks, seen tracking, preferences.
            await m.createTable(dailyPicks);
            await m.createTable(seen);
            await m.createTable(preferenceEntries);
          }
          if (from < 3) {
            // v3 (Phase 5): saved stories.
            await m.createTable(bookmarks);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // --- sources -----------------------------------------------------------------------------

  /// Inserts new bundled sources and refreshes metadata of existing ones, keeping
  /// the user's enabled flag and the fetch state. Sources no longer bundled are disabled.
  Future<void> upsertBundledSources(List<domain.Source> bundled) async {
    await transaction(() async {
      final bundledIds = bundled.map((s) => s.id).toSet();
      for (final s in bundled) {
        final existing = await (select(sources)..where((t) => t.id.equals(s.id))).getSingleOrNull();
        final companion = SourcesCompanion(
          id: Value(s.id),
          name: Value(s.name),
          homepageUrl: Value(s.homepageUrl),
          rssUrl: Value(s.rssUrl),
          tier: Value(s.tier),
          trustScore: Value(s.trustScore),
          language: Value(s.language),
          regions: Value(s.regions),
        );
        if (existing == null) {
          await into(sources).insert(companion);
        } else {
          await (update(sources)..where((t) => t.id.equals(s.id))).write(companion);
        }
      }
      await (update(sources)..where((t) => t.id.isNotIn(bundledIds)))
          .write(const SourcesCompanion(userEnabled: Value(false)));
    });
  }

  Future<List<SourceRow>> enabledSources() =>
      (select(sources)
            ..where((t) => t.userEnabled.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.tier), (t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<List<SourceRow>> allSources() =>
      (select(sources)..orderBy([(t) => OrderingTerm.asc(t.tier), (t) => OrderingTerm.asc(t.name)])).get();

  Future<void> setSourceEnabled(String id, bool enabled) =>
      (update(sources)..where((t) => t.id.equals(id))).write(SourcesCompanion(userEnabled: Value(enabled)));

  Future<void> recordFetchSuccess(
    String sourceId, {
    required DateTime at,
    required String etag,
    required String lastModified,
    required String status,
  }) =>
      (update(sources)..where((t) => t.id.equals(sourceId))).write(SourcesCompanion(
        etag: Value(etag),
        lastModified: Value(lastModified),
        lastFetchedAt: Value(at),
        lastStatus: Value(status),
        consecutiveFailures: const Value(0),
        backoffUntil: const Value(null),
      ));

  Future<void> recordFetchFailure(
    String sourceId, {
    required String status,
    required int failures,
    DateTime? backoffUntil,
  }) =>
      (update(sources)..where((t) => t.id.equals(sourceId))).write(SourcesCompanion(
        lastStatus: Value(status),
        consecutiveFailures: Value(failures),
        backoffUntil: Value(backoffUntil),
      ));

  // --- articles ----------------------------------------------------------------------------

  /// Stores items whose canonical URL is not yet known. Returns how many were new.
  /// Safe to call repeatedly with the same items (idempotent).
  Future<int> insertNewArticles(
    String sourceId,
    List<NormalizedItem> items,
    DateTime fetchedAt, {
    Map<String, Classification> classifications = const {},
  }) async {
    if (items.isEmpty) return 0;
    return transaction(() async {
      final urls = items.map((i) => i.canonicalUrl).toSet();
      final known = <String>{};
      for (final chunk in _chunks(urls.toList(), 500)) {
        final rows = await (selectOnly(articles)
              ..addColumns([articles.canonicalUrl])
              ..where(articles.canonicalUrl.isIn(chunk)))
            .get();
        known.addAll(rows.map((r) => r.read(articles.canonicalUrl)!));
      }
      var inserted = 0;
      final seen = <String>{};
      for (final item in items) {
        if (known.contains(item.canonicalUrl) || !seen.add(item.canonicalUrl)) continue;
        final c = classifications[item.canonicalUrl];
        final rows = await into(articles).insert(
          ArticlesCompanion.insert(
            id: articleIdFor(item.canonicalUrl),
            sourceId: sourceId,
            canonicalUrl: item.canonicalUrl,
            title: item.title,
            excerpt: item.excerpt,
            publishedAt: item.publishedAt,
            fetchedAt: fetchedAt,
            language: item.language,
            regions: item.regions,
            topics: c == null ? item.topics : mergeTopics(c.topics, item.topics),
            storyTypes: Value(c?.storyTypes ?? const []),
            evidenceSignals: Value(c?.evidenceSignals ?? const []),
            constructiveScore: Value(c?.score),
            route: Value(c?.route),
            explanation: Value(c == null ? null : jsonEncode(c.explanationJson())),
            rulesVersion: Value(c?.rulesVersion),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        if (rows != 0) inserted++;
      }
      return inserted;
    });
  }

  Future<int> articleCount() async {
    final count = articles.id.count();
    final row = await (selectOnly(articles)..addColumns([count])).getSingle();
    return row.read(count)!;
  }

  Future<List<ArticleRow>> latestArticles({int limit = 50}) => (select(articles)
        ..orderBy([(t) => OrderingTerm.desc(t.publishedAt)])
        ..limit(limit))
      .get();

  // --- classification ---------------------------------------------------------------------

  /// Articles whose stored classification is missing or was made with another rules version,
  /// together with the source data the classifier needs.
  Future<List<(ArticleRow, SourceRow)>> articlesNeedingClassification(String rulesVersion) async {
    final query = select(articles).join([innerJoin(sources, sources.id.equalsExp(articles.sourceId))])
      ..where(articles.rulesVersion.isNull() | articles.rulesVersion.equals(rulesVersion).not());
    return (await query.get()).map((r) => (r.readTable(articles), r.readTable(sources))).toList();
  }

  Future<void> updateClassification(String articleId, Classification c, List<String> feedTopics) =>
      (update(articles)..where((t) => t.id.equals(articleId))).write(ArticlesCompanion(
        topics: Value(mergeTopics(c.topics, feedTopics)),
        storyTypes: Value(c.storyTypes),
        evidenceSignals: Value(c.evidenceSignals),
        constructiveScore: Value(c.score),
        route: Value(c.route),
        explanation: Value(jsonEncode(c.explanationJson())),
        rulesVersion: Value(c.rulesVersion),
      ));

  // --- de-duplication clusters --------------------------------------------------------------

  /// Shown-eligible articles (today/explore) published since [since], for clustering.
  Future<List<ArticleRow>> clusterableArticles(DateTime since) => (select(articles)
        ..where((t) => t.route.isIn([routeToday, routeExplore]) & t.publishedAt.isBiggerOrEqualValue(since)))
      .get();

  Future<void> setClusterIds(Map<String, String?> byArticleId) async {
    await batch((b) {
      byArticleId.forEach((id, cluster) {
        b.update(articles, ArticlesCompanion(clusterId: Value(cluster)), where: (t) => t.id.equals(id));
      });
    });
  }

  // --- picks, seen, preferences -------------------------------------------------------------

  /// Eligible pick candidates: shown routes, not hidden, newer than [cutoff], enabled sources.
  Future<List<(ArticleRow, SourceRow)>> pickCandidates(DateTime cutoff) async {
    final query = select(articles).join([innerJoin(sources, sources.id.equalsExp(articles.sourceId))])
      ..where(articles.route.isIn([routeToday, routeExplore]) &
          articles.hidden.equals(false) &
          articles.publishedAt.isBiggerOrEqualValue(cutoff) &
          sources.userEnabled.equals(true));
    return (await query.get()).map((r) => (r.readTable(articles), r.readTable(sources))).toList();
  }

  Future<List<DailyPickRow>> picksForDay(String day) => (select(dailyPicks)
        ..where((t) => t.day.equals(day))
        ..orderBy([(t) => OrderingTerm.asc(t.position)]))
      .get();

  /// Ids of articles picked on any day other than [day] (a briefing never repeats a story).
  Future<Set<String>> pickedArticleIdsExceptDay(String day) async =>
      (await (select(dailyPicks)..where((t) => t.day.equals(day).not())).get()).map((r) => r.articleId).toSet();

  /// Appends [articleIds] after the day's existing picks. Never reorders or removes.
  Future<void> appendPicks(String day, List<String> articleIds) async {
    if (articleIds.isEmpty) return;
    await transaction(() async {
      final existing = await picksForDay(day);
      var position = existing.isEmpty ? 0 : existing.last.position + 1;
      final already = existing.map((p) => p.articleId).toSet();
      for (final id in articleIds) {
        if (!already.add(id)) continue; // a story is never picked twice on one day
        await into(dailyPicks).insert(
          DailyPicksCompanion.insert(day: day, position: position++, articleId: id),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// Articles by id, in the order of [ids] (missing ids are skipped).
  Future<List<ArticleRow>> articlesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await (select(articles)..where((t) => t.id.isIn(ids))).get();
    final byId = {for (final r in rows) r.id: r};
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  /// Records stories as seen. Ids without an article row (for example a saved story whose
  /// article has been cleaned up) are ignored: there is nothing to pick again.
  Future<void> markSeen(Iterable<String> articleIds, DateTime at) async {
    final ids = articleIds.toSet().toList();
    if (ids.isEmpty) return;
    final existing = (await (selectOnly(articles)
              ..addColumns([articles.id])
              ..where(articles.id.isIn(ids)))
            .get())
        .map((r) => r.read(articles.id)!)
        .toSet();
    await batch((b) {
      b.insertAll(
        seen,
        [for (final id in ids) if (existing.contains(id)) SeenCompanion.insert(articleId: id, seenAt: at)],
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  Future<Set<String>> seenIds() async =>
      (await select(seen).get()).map((r) => r.articleId).toSet();

  // --- single rows, bookmarks ---------------------------------------------------------------

  Future<(ArticleRow, SourceRow)?> articleWithSource(String id) async {
    final query = select(articles).join([innerJoin(sources, sources.id.equalsExp(articles.sourceId))])
      ..where(articles.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : (row.readTable(articles), row.readTable(sources));
  }

  Future<void> addBookmark(String articleId, String snapshotJson, DateTime at) => into(bookmarks)
      .insertOnConflictUpdate(BookmarksCompanion.insert(articleId: articleId, savedAt: at, snapshot: snapshotJson));

  Future<void> removeBookmark(String articleId) =>
      (delete(bookmarks)..where((t) => t.articleId.equals(articleId))).go();

  /// Newest saved first.
  Future<List<BookmarkRow>> allBookmarks() =>
      (select(bookmarks)..orderBy([(t) => OrderingTerm.desc(t.savedAt), (t) => OrderingTerm.asc(t.articleId)])).get();

  Future<Set<String>> bookmarkedIds() async =>
      (await select(bookmarks).get()).map((r) => r.articleId).toSet();

  Future<String?> getPreference(String key) async =>
      (await (select(preferenceEntries)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setPreference(String key, String value) => into(preferenceEntries)
      .insertOnConflictUpdate(PreferenceEntriesCompanion.insert(key: key, value: value));

  /// Deletes articles published before [cutoff], except bookmarked ones.
  Future<int> pruneArticles(DateTime cutoff) => (delete(articles)
        ..where((t) =>
            t.publishedAt.isSmallerThanValue(cutoff) &
            t.id.isNotInQuery(selectOnly(bookmarks)..addColumns([bookmarks.articleId]))))
      .go();
}

Iterable<List<T>> _chunks<T>(List<T> list, int size) sync* {
  for (var i = 0; i < list.length; i += size) {
    yield list.sublist(i, i + size > list.length ? list.length : i + size);
  }
}

/// Classifier topics first, then any feed-category topics not already present.
List<String> mergeTopics(List<String> classifier, List<String> feed) =>
    [...classifier, ...feed.where((t) => !classifier.contains(t))];

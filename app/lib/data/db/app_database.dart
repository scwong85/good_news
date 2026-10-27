import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../domain/source.dart' as domain;
import '../../pipeline/normalize.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// First 16 hex characters of sha1(canonicalUrl): the article id.
String articleIdFor(String canonicalUrl) =>
    sha1.convert(utf8.encode(canonicalUrl)).toString().substring(0, 16);

@DriftDatabase(tables: [Sources, Articles])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

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
  Future<int> insertNewArticles(String sourceId, List<NormalizedItem> items, DateTime fetchedAt) async {
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
            topics: item.topics,
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

  /// Deletes articles published before [cutoff]. (Bookmarked articles will be excluded
  /// once the bookmarks table exists in Phase 5.)
  Future<int> pruneArticles(DateTime cutoff) =>
      (delete(articles)..where((t) => t.publishedAt.isSmallerThanValue(cutoff))).go();
}

Iterable<List<T>> _chunks<T>(List<T> list, int size) sync* {
  for (var i = 0; i < list.length; i += size) {
    yield list.sublist(i, i + size > list.length ? list.length : i + size);
  }
}

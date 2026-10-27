import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/data/db/app_database.dart';
import 'package:good_news/selection/dedupe_service.dart';

import '../ingestion/test_support.dart';

void main() {
  late AppDatabase db;
  final clock = FakeClock();
  late DedupeService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.upsertBundledSources([source('a'), source('b')]);
    service = DedupeService(db, now: clock.call);
  });
  tearDown(() => db.close());

  Future<String?> clusterOf(String id) async => (await db.articlesByIds([id])).single.clusterId;

  test('assigns the earliest member as cluster id and leaves singletons null', () async {
    final first = await addArticle(db, 'a', slug: '1', title: 'Hungary repeals anti-LGBTQ law, unlocking billions in EU funds', publishedAt: DateTime.utc(2026, 10, 26, 8));
    final second = await addArticle(db, 'b', slug: '2', title: 'Hungary repeals anti-LGBTQ law and unlocks billions in EU funds', publishedAt: DateTime.utc(2026, 10, 27, 8));
    final lone = await addArticle(db, 'a', slug: '3', title: 'Beavers return to the Oregon wilderness', publishedAt: DateTime.utc(2026, 10, 27, 9));
    expect(await service.refreshClusters(), 2);
    expect(await clusterOf(first), first);
    expect(await clusterOf(second), first);
    expect(await clusterOf(lone), isNull);
  });

  test('is idempotent', () async {
    await addArticle(db, 'a', slug: '1', title: 'Hungary repeals anti-LGBTQ law, unlocking billions in EU funds');
    await addArticle(db, 'b', slug: '2', title: 'Hungary repeals anti-LGBTQ law and unlocks billions in EU funds');
    expect(await service.refreshClusters(), 2);
    expect(await service.refreshClusters(), 0);
  });

  test('excluded and unclassified articles are not clustered', () async {
    final x = await addArticle(db, 'a', slug: '1', title: 'Hungary repeals anti-LGBTQ law, unlocking billions in EU funds', route: 'excluded');
    await addArticle(db, 'b', slug: '2', title: 'Hungary repeals anti-LGBTQ law and unlocks billions in EU funds');
    expect(await service.refreshClusters(), 0);
    expect(await clusterOf(x), isNull);
  });

  test('articles older than the lookback window are left alone', () async {
    final old = await addArticle(db, 'a', slug: '1', title: 'Hungary repeals anti-LGBTQ law, unlocking billions in EU funds', publishedAt: DateTime.utc(2026, 10, 1));
    await (db.update(db.articles)..where((t) => t.id.equals(old))).write(const ArticlesCompanion(clusterId: Value('keep')));
    await service.refreshClusters();
    expect(await clusterOf(old), 'keep');
  });

  test('a cluster dissolves when the match no longer holds', () async {
    final a = await addArticle(db, 'a', slug: '1', title: 'Hungary repeals anti-LGBTQ law, unlocking billions in EU funds');
    final b = await addArticle(db, 'b', slug: '2', title: 'Hungary repeals anti-LGBTQ law and unlocks billions in EU funds');
    await service.refreshClusters();
    await (db.update(db.articles)..where((t) => t.id.equals(b))).write(const ArticlesCompanion(route: Value('excluded')));
    await service.refreshClusters();
    expect(await clusterOf(a), isNull);
  });
}

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/data/db/app_database.dart';
import 'package:good_news/data/story_repository.dart';

import '../ingestion/test_support.dart';

void main() {
  late AppDatabase db;
  late StoryRepository repo;
  final now = DateTime.utc(2026, 10, 27, 12);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = StoryRepository(db, now: () => now);
    await db.upsertBundledSources([source('a'), source('b')]);
  });
  tearDown(() => db.close());

  Future<String> add(String src, String slug,
          {String title = '', String route = 'today', double score = 0.6, int hoursOld = 5, List<String> topics = const ['environment']}) =>
      addArticle(db, src, slug: slug, title: title.isEmpty ? 'Story $slug' : title, route: route, score: score, topics: topics, publishedAt: now.subtract(Duration(hours: hoursOld)));

  group('explore', () {
    test('lists shown stories newest first and nothing else', () async {
      await add('a', 'old', hoursOld: 30);
      await add('a', 'new', hoursOld: 2);
      await add('b', 'excluded', route: 'excluded');
      final titles = (await repo.explore(const ExploreQuery())).map((s) => s.title).toList();
      expect(titles, ['Story new', 'Story old']);
    });

    test('only the last two weeks, enabled sources and unhidden stories', () async {
      await add('a', 'recent');
      await add('a', 'ancient', hoursOld: 24 * 20);
      final hidden = await add('a', 'hidden');
      await add('b', 'disabled-source');
      await (db.update(db.articles)..where((t) => t.id.equals(hidden))).write(const ArticlesCompanion(hidden: Value(true)));
      await db.setSourceEnabled('b', false);
      expect((await repo.explore(const ExploreQuery())).map((s) => s.title), ['Story recent']);
    });

    test('text search matches every word in title, excerpt or source name, ignoring case', () async {
      await add('a', 'wet1', title: 'Wetlands restored by volunteers');
      await add('b', 'sol2', title: 'Solar farms shelter owls');
      Future<List<String>> find(String q) async => (await repo.explore(ExploreQuery(text: q))).map((s) => s.title).toList();
      expect(await find('WETLANDS'), ['Wetlands restored by volunteers']);
      expect(await find('wetlands volunteers'), ['Wetlands restored by volunteers']);
      expect(await find('wetlands owls'), isEmpty);
      expect(await find('source'), hasLength(2)); // neither title nor excerpt says "source": it matched the source names
      expect(await find('excerpt wet1'), ['Wetlands restored by volunteers']);
      expect(await find('   '), hasLength(2));
    });

    test('topic, story type and region filters match any selected value', () async {
      await add('a', 'env', topics: ['environment']);
      await add('a', 'health', topics: ['health']);
      await add('b', 'sci', topics: ['science']);
      Future<int> n(ExploreQuery q) async => (await repo.explore(q)).length;
      expect(await n(const ExploreQuery(topics: {'health'})), 1);
      expect(await n(const ExploreQuery(topics: {'health', 'science'})), 2);
      expect(await n(const ExploreQuery(regions: {'global'})), 3);
      expect(await n(const ExploreQuery(regions: {'asia'})), 0);
      expect(await n(const ExploreQuery(storyTypes: {'solution'})), 0);
      expect(await n(const ExploreQuery(topics: {'health'}, text: 'env')), 0); // filters combine with AND
    });

    test('duplicates collapse to the best scored story of the cluster', () async {
      final lo = await add('a', 'lo', score: 0.5);
      final hi = await add('b', 'hi', score: 0.9);
      await add('a', 'other', score: 0.4, hoursOld: 9);
      for (final id in [lo, hi]) {
        await (db.update(db.articles)..where((t) => t.id.equals(id))).write(const ArticlesCompanion(clusterId: Value('k')));
      }
      expect((await repo.explore(const ExploreQuery())).map((s) => s.title), ['Story hi', 'Story other']);
    });

    test('is capped at the limit', () async {
      final small = StoryRepository(db, now: () => now, exploreLimit: 3);
      for (var i = 0; i < 6; i++) {
        await add('a', 'n$i', hoursOld: i + 1);
      }
      expect(await small.explore(const ExploreQuery()), hasLength(3));
    });

    test('marks saved stories', () async {
      final id = await add('a', 'x');
      final story = (await repo.explore(const ExploreQuery())).single;
      expect(story.saved, isFalse);
      await repo.save(story);
      expect((await repo.explore(const ExploreQuery())).single.saved, isTrue);
      expect(id, story.id);
    });
  });

  group('single stories and saved', () {
    test('byId finds an article, falls back to the saved snapshot, then to null', () async {
      final id = await add('a', 'x');
      final story = (await repo.byId(id))!;
      expect((story.title, story.sourceName, story.fromSnapshot), ('Story x', 'Source a', false));
      await repo.save(story);
      await db.customStatement('DELETE FROM articles');
      final fromSnapshot = (await repo.byId(id))!;
      expect((fromSnapshot.title, fromSnapshot.fromSnapshot, fromSnapshot.saved), ('Story x', true, true));
      expect(await repo.byId('unknown'), isNull);
    });

    test('saving twice keeps one copy; unsaving removes it', () async {
      final id = await add('a', 'x');
      final story = (await repo.byId(id))!;
      await repo.save(story);
      await repo.save(story);
      expect(await repo.saved(), hasLength(1));
      await repo.unsave(id);
      expect(await repo.saved(), isEmpty);
      await repo.unsave(id); // harmless
    });

    test('saved stories come newest saved first', () async {
      final a = await add('a', 'one');
      final b = await add('a', 'two');
      var clock = now;
      final timed = StoryRepository(db, now: () => clock);
      await timed.save((await timed.byId(a))!);
      clock = clock.add(const Duration(minutes: 5));
      await timed.save((await timed.byId(b))!);
      expect((await timed.saved()).map((s) => s.id), [b, a]);
    });

    test('fromArticles keeps order and skips articles of unknown sources', () async {
      final a = await add('a', 'one');
      final b = await add('b', 'two');
      final rows = await db.articlesByIds([b, a]);
      expect((await repo.fromArticles(rows)).map((s) => s.id), [b, a]);
      expect(await repo.fromArticles(const []), isEmpty);
    });

    test('markSeen records known stories only', () async {
      final id = await add('a', 'x');
      await repo.markSeen(id);
      await repo.markSeen('gone');
      expect(await db.seenIds(), {id});
    });
  });

  test('availableRegions lists regions of shown stories', () async {
    await add('a', 'x');
    expect(await repo.availableRegions(), ['global']);
  });
}

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/data/db/app_database.dart';
import 'package:good_news/selection/daily_picks_service.dart';
import 'package:good_news/selection/dedupe_service.dart';
import 'package:good_news/selection/preferences.dart';

import '../ingestion/test_support.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late PreferencesRepository prefs;
  late DailyPicksService service;

  Future<void> boot({List<String> sources = const ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']}) async {
    db = AppDatabase(NativeDatabase.memory());
    clock = FakeClock(DateTime.utc(2026, 10, 27, 12));
    prefs = PreferencesRepository(db);
    service = DailyPicksService(db, prefs, now: clock.call);
    await db.upsertBundledSources(sources.map(source).toList());
  }

  /// n stories spread over distinct sources/topics, scores descending from [top].
  Future<List<String>> seed(int n, {String prefix = 's', String route = 'today', double top = 0.8, int ageHours = 3}) async {
    final ids = <String>[];
    for (var i = 0; i < n; i++) {
      ids.add(await addArticle(
        db,
        String.fromCharCode('a'.codeUnitAt(0) + (i % 8)),
        slug: '$prefix$i',
        route: route,
        score: top - i * 0.01,
        topics: ['topic$prefix$i'],
        publishedAt: clock.value.subtract(Duration(hours: ageHours)),
      ));
    }
    return ids;
  }

  tearDown(() => db.close());

  test('creates stories_per_day picks and persists them', () async {
    await boot();
    await seed(12);
    final picks = await service.todaysPicks();
    expect(picks, hasLength(5));
    final stored = await db.picksForDay(DailyPicksService.dayKey(clock.value));
    expect(stored.map((p) => p.position), [0, 1, 2, 3, 4]);
    expect(stored.map((p) => p.articleId), picks.map((a) => a.id));
  });

  test('the picks are stable all day, even when better stories arrive', () async {
    await boot();
    await seed(12);
    final first = (await service.todaysPicks()).map((a) => a.id).toList();
    await seed(5, prefix: 'new', top: 0.99, ageHours: 0); // clearly better stories
    clock.advance(const Duration(hours: 3));
    expect((await service.todaysPicks()).map((a) => a.id), first);
    expect((await service.todaysPicks()).map((a) => a.id), first);
  });

  test('raising stories_per_day appends; lowering shows a prefix; raising again restores', () async {
    await boot();
    await seed(15);
    final five = (await service.todaysPicks()).map((a) => a.id).toList();
    await prefs.setStoriesPerDay(8);
    final eight = (await service.todaysPicks()).map((a) => a.id).toList();
    expect(eight, hasLength(8));
    expect(eight.take(5), five);
    await prefs.setStoriesPerDay(6);
    expect((await service.todaysPicks()).map((a) => a.id), eight.take(6));
    await prefs.setStoriesPerDay(8);
    expect((await service.todaysPicks()).map((a) => a.id), eight);
    await prefs.setStoriesPerDay(10);
    expect(await service.todaysPicks(), hasLength(10));
  });

  test('a short day is topped up as more stories arrive, without reordering', () async {
    await boot();
    await seed(3);
    final first = (await service.todaysPicks()).map((a) => a.id).toList();
    expect(first, hasLength(3));
    await seed(6, prefix: 'late');
    final later = (await service.todaysPicks()).map((a) => a.id).toList();
    expect(later, hasLength(5));
    expect(later.take(3), first);
  });

  test('a new day gets new picks and never repeats yesterday\'s stories', () async {
    await boot();
    await seed(14);
    final day1 = (await service.todaysPicks()).map((a) => a.id).toSet();
    clock.advance(const Duration(hours: 26));
    final day2 = (await service.todaysPicks()).map((a) => a.id).toSet();
    expect(day2, hasLength(5));
    expect(day2.intersection(day1), isEmpty);
    expect(DailyPicksService.dayKey(clock.value), isNot(DailyPicksService.dayKey(clock.value.subtract(const Duration(hours: 26)))));
  });

  test('seen stories, and duplicates of seen stories, are not picked', () async {
    await boot();
    final ids = await seed(10);
    final dupSource = await addArticle(db, 'h', slug: 'dup', title: 'Story ${ids[0]} headline words zebra', score: 0.99);
    await (db.update(db.articles)..where((t) => t.id.equals(dupSource))).write(const ArticlesCompanion(clusterId: Value('c1')));
    await (db.update(db.articles)..where((t) => t.id.equals(ids[0]))).write(const ArticlesCompanion(clusterId: Value('c1')));
    await service.markSeen([ids[0], ids[1]]);
    final picked = (await service.todaysPicks()).map((a) => a.id).toSet();
    expect(picked, isNot(contains(ids[0])));
    expect(picked, isNot(contains(ids[1])));
    expect(picked, isNot(contains(dupSource))); // same cluster as a seen story
  });

  test('disabled sources and hidden stories are never picked', () async {
    await boot();
    final ids = await seed(12);
    await db.setSourceEnabled('a', false);
    await (db.update(db.articles)..where((t) => t.id.equals(ids[1]))).write(const ArticlesCompanion(hidden: Value(true)));
    final picks = await service.todaysPicks();
    expect(picks.map((a) => a.sourceId), isNot(contains('a')));
    expect(picks.map((a) => a.id), isNot(contains(ids[1])));
  });

  test('excluded, unclassified and too-old stories are ignored', () async {
    await boot();
    await seed(2, prefix: 'ok');
    await seed(5, prefix: 'ex', route: 'excluded');
    await seed(5, prefix: 'old', ageHours: 24 * 20);
    final picks = await service.todaysPicks();
    expect(picks, hasLength(2));
    expect(picks.every((a) => a.title.contains('ok')), isTrue);
  });

  test('explore stories fill the day when there are too few today stories', () async {
    await boot();
    await seed(2, prefix: 't');
    await seed(8, prefix: 'e', route: 'explore');
    final picks = await service.todaysPicks();
    expect(picks.map((a) => a.route).take(2), ['today', 'today']);
    expect(picks.skip(2).map((a) => a.route), everyElement('explore'));
    expect(picks, hasLength(5));
  });

  test('no more than two stories from one source while others are available', () async {
    await boot();
    for (var i = 0; i < 6; i++) {
      await addArticle(db, 'a', slug: 'a$i', score: 0.9 - i * 0.01, topics: ['ta$i']);
    }
    await seed(6, prefix: 'o'); // other sources (note: also uses source a for i%8==0)
    final picks = await service.todaysPicks();
    expect(picks.where((a) => a.sourceId == 'a').length, lessThanOrEqualTo(2));
  });

  test('the same data gives the same picks in two independent databases', () async {
    await boot();
    await seed(12);
    final first = (await service.todaysPicks()).map((a) => a.id).toList();
    await db.close();
    await boot();
    await seed(12);
    expect((await service.todaysPicks()).map((a) => a.id), first);
  });

  test('duplicate stories never appear together in a day\'s picks', () async {
    await boot();
    await seed(8, prefix: 'f');
    const t = 'Wildlife vets give rare hornbill 3D-printed beak in world-first';
    final a = await addArticle(db, 'a', slug: 'h1', title: t, score: 0.95, publishedAt: DateTime.utc(2026, 10, 27, 7));
    final b = await addArticle(db, 'b', slug: 'h2', title: 'Meet the World’s First Bird With 3D-Printed Upper and Lower Beak Prostheses hornbill', score: 0.94, publishedAt: DateTime.utc(2026, 10, 27, 8));
    await DedupeService(db, now: clock.call).refreshClusters();
    await prefs.setStoriesPerDay(10);
    final ids = (await service.todaysPicks()).map((x) => x.id);
    expect(ids.where((id) => id == a || id == b), hasLength(1));
  });

  test('works with nothing to pick', () async {
    await boot();
    expect(await service.todaysPicks(), isEmpty);
  });

  test('dayKey uses the local calendar day', () {
    expect(DailyPicksService.dayKey(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
    expect(DailyPicksService.dayKey(DateTime(2026, 12, 31, 0, 0)), '2026-12-31');
  });
}

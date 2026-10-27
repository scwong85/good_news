import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/data/db/app_database.dart';
import 'package:good_news/selection/daily_picks_service.dart';
import 'package:good_news/selection/preferences.dart';
import 'package:http/http.dart' as http;

import '../ingestion/test_support.dart';

void main() {
  late Harness h;
  tearDown(() => h.close());

  DateTime ago(Duration d) => h.clock.value.subtract(d);

  List<int> feedOf(String id, List<(String, String)> stories, {List<String> categories = const []}) => rss([
        for (final (i, s) in stories.indexed)
          rssItem(s.$1, 'https://$id.example.com/${s.$2}', ago(Duration(hours: 2 + i)), desc: 'An excerpt for ${s.$2}.')
              .replaceFirst('</item>', '${categories.map((c) => '<category>$c</category>').join()}</item>'),
      ]);

  test('new articles are classified on insert and keep their explanation', () async {
    h = Harness(classify: true, routes: {
      'a': (_) => feed(feedOf('a', [
            ('Wetlands restored by volunteers, study finds 40% more birds', 'wet'),
            ('Attack kills dozens as war crisis deepens', 'war'),
          ], categories: ['Environment'])),
    });
    await h.addSources(['a']);
    await h.service.refresh();
    final rows = {for (final r in await h.db.latestArticles()) r.canonicalUrl: r};
    final good = rows['https://a.example.com/wet']!;
    expect(good.route, 'today');
    expect(good.constructiveScore, greaterThan(0.5));
    expect(good.rulesVersion, h.classification!.rules.version);
    expect(good.evidenceSignals, containsAll(['data_cited', 'study_referenced']));
    expect(good.topics, contains('environment'));
    final explanation = jsonDecode(good.explanation!) as Map<String, dynamic>;
    expect((explanation['rules'] as List).map((r) => r['rule']), contains('progress_terms'));
    final bad = rows['https://a.example.com/war']!;
    expect(bad.route, 'excluded'); // stored, so it is not reprocessed
    expect(bad.explanation, isNotNull);
  });

  test('feed-category topics are kept alongside the classifier topics', () async {
    h = Harness(classify: true, routes: {
      'a': (_) => feed(feedOf('a', [('Volunteers restored a school garden', 'g')], categories: ['Culture'])),
    });
    await h.addSources(['a']);
    await h.service.refresh();
    expect((await h.db.latestArticles()).single.topics, contains('culture'));
  });

  test('stage-1 exclusions are applied with the source name (roundups never reach the feed)', () async {
    h = Harness(classify: true, routes: {
      'a': (_) => feed(feedOf('a', [('Good News This Week: October 24, 2026 - Mangroves', 'roundup')])),
    });
    await h.addSources(['a']);
    await h.service.refresh();
    final row = (await h.db.latestArticles()).single;
    expect(row.route, 'excluded');
    expect(jsonDecode(row.explanation!)['reason'], 'stage1:roundup_good_news');
  });

  test('articles classified under another rules version are re-classified', () async {
    h = Harness(classify: true, routes: {'a': (_) => feed(feedOf('a', [('Wetlands restored by volunteers, study finds 40% more birds', 'wet')]))});
    await h.addSources(['a']);
    await h.service.refresh();
    final id = (await h.db.latestArticles()).single.id;
    await (h.db.update(h.db.articles)..where((t) => t.id.equals(id))).write(const ArticlesCompanion(
      rulesVersion: Value('ancient'),
      route: Value('excluded'),
      constructiveScore: Value(0),
    ));
    expect(await h.classification!.reclassifyOutdated(), 1);
    final row = (await h.db.latestArticles()).single;
    expect((row.rulesVersion, row.route), (h.classification!.rules.version, 'today'));
    expect(await h.classification!.reclassifyOutdated(), 0); // up to date: nothing to do
  });

  test('unclassified legacy rows (Phase 3 data) are classified after the next refresh', () async {
    h = Harness(classify: true, routes: {'a': (_) => feed(feedOf('a', []))});
    await h.addSources(['a']);
    await addArticle(h.db, 'a', slug: 'legacy', title: 'Wetlands restored by volunteers, study finds 40% more birds');
    await (h.db.update(h.db.articles)).write(const ArticlesCompanion(rulesVersion: Value(null), route: Value(null)));
    await h.service.refresh(force: true);
    expect((await h.db.latestArticles()).single.route, isNotNull);
  });

  test('a failing after-refresh hook never fails the refresh', () async {
    h = Harness(classify: true, extraHooks: [() async => throw StateError('boom')], routes: {
      'a': (_) => feed(feedOf('a', [('Wetlands restored by volunteers', 'wet')])),
    });
    await h.addSources(['a']);
    final report = await h.service.refresh();
    expect(report.totalNew, 1);
  });

  test('end to end: duplicates across sources are clustered and only one is picked', () async {
    const dupA = 'Wildlife vets give rare hornbill 3D-printed beak in world-first';
    const dupB = 'Meet the World’s First Bird With 3D-Printed Upper and Lower Beak Prostheses';
    h = Harness(classify: true, routes: {
      'a': (_) => feed(feedOf('a', [(dupA, 'hornbill'), ('Wetlands restored by volunteers, study finds 40% more birds', 'wet')])),
      'b': (_) => feed(feedOf('b', [(dupB, 'bird-beak'), ('Clinic opens free care for families, study finds 30% fewer ER visits', 'clinic')])),
    });
    await h.addSources(['a', 'b']);
    await h.service.refresh();
    final rows = await h.db.latestArticles();
    final dups = rows.where((r) => r.title == dupA || r.title == dupB).toList();
    expect(dups, hasLength(2));
    expect(dups.map((r) => r.clusterId).toSet(), hasLength(1));
    expect(dups.first.clusterId, isNotNull);

    final service = DailyPicksService(h.db, PreferencesRepository(h.db), now: h.clock.call);
    await PreferencesRepository(h.db).setStoriesPerDay(10);
    final picks = await service.todaysPicks();
    expect(picks.where((p) => p.title == dupA || p.title == dupB).length, lessThanOrEqualTo(1));
    expect(picks, isNotEmpty);
  });

  test('without a classification service the pipeline still works (Phase 3 behaviour)', () async {
    h = Harness(routes: {'a': (_) => feed(feedOf('a', [('Wetlands restored by volunteers', 'wet')]))});
    await h.addSources(['a']);
    await h.service.refresh();
    final row = (await h.db.latestArticles()).single;
    expect((row.route, row.rulesVersion), (null, null));
  });

  test('a failing source does not stop classification of the others', () async {
    h = Harness(classify: true, routes: {
      'a': (_) async => http.Response('boom', 500),
      'b': (_) => feed(feedOf('b', [('Wetlands restored by volunteers, study finds 40% more birds', 'wet')])),
    });
    await h.addSources(['a', 'b']);
    final report = await h.service.refresh();
    expect(report.failed, 1);
    expect((await h.db.latestArticles()).single.route, 'today');
  });
}

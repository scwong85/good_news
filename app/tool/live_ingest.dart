// ignore_for_file: avoid_print
// Dev tool: runs the real fetch-on-open pipeline against the live feeds (not part of the tests).
//
//   cd app && dart run tool/live_ingest.dart
//
// Fetches every bundled source twice into an in-memory database (classification and duplicate
// clustering included), then prints today's picks, so you can check parsing, rules and selection
// against real-world feeds and see that a rerun adds nothing new.
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:good_news/classification/classification_service.dart';
import 'package:good_news/data/db/app_database.dart';
import 'package:good_news/data/http/feed_fetcher.dart';
import 'package:good_news/data/sources/direct_rss_story_source.dart';
import 'package:good_news/domain/source.dart';
import 'package:good_news/ingestion/ingestion_service.dart';
import 'package:good_news/pipeline/rules.dart';
import 'package:good_news/selection/daily_picks_service.dart';
import 'package:good_news/selection/dedupe_service.dart';
import 'package:good_news/selection/preferences.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final perDay = args.isNotEmpty ? int.parse(args.first) : 7;
  final json = jsonDecode(File('assets/sources.json').readAsStringSync()) as Map<String, dynamic>;
  final sources = (json['sources'] as List).map((s) => Source.fromJson(s as Map<String, dynamic>)).toList();
  final rules = Rules.parse(File('assets/rules/rules.json').readAsStringSync());
  final db = AppDatabase(NativeDatabase.memory());
  final client = http.Client();
  final classification = ClassificationService(db, rules);
  final service = IngestionService(
    db: db,
    storySource: DirectRssStorySource(FeedFetcher(client)),
    deadline: const Duration(seconds: 30),
    classification: classification,
    afterRefresh: [classification.reclassifyOutdated, DedupeService(db).refreshClusters],
  );
  await db.upsertBundledSources(sources);

  for (final pass in [1, 2]) {
    final sw = Stopwatch()..start();
    final report = await service.refresh(force: true);
    print('--- pass $pass: ${sw.elapsedMilliseconds} ms, ${report.totalNew} new, ${report.failed} failed');
    if (pass == 1) {
      for (final o in report.outcomes) {
        print('${o.sourceId.padRight(24)} ${o.status.name.padRight(8)} seen=${o.itemsSeen} '
            'new=${o.itemsNew} skipped=${o.itemsSkipped} ${o.error ?? ''}');
      }
    }
  }

  final all = await db.latestArticles(limit: 100000);
  final routes = <String, int>{};
  for (final a in all) {
    routes[a.route ?? 'none'] = (routes[a.route ?? 'none'] ?? 0) + 1;
  }
  final clustered = all.where((a) => a.clusterId != null).length;
  print('--- stored ${all.length}; routes $routes; in duplicate clusters: $clustered');

  final prefs = PreferencesRepository(db);
  await prefs.setStoriesPerDay(perDay);
  final picks = await DailyPicksService(db, prefs).todaysPicks();
  print("--- today's picks (stories_per_day=$perDay): ${picks.length}");
  for (final a in picks) {
    final src = sources.firstWhere((s) => s.id == a.sourceId).name;
    print('[${a.route} ${a.constructiveScore!.toStringAsFixed(2)}] ${a.title}');
    print('      $src · ${a.publishedAt.toUtc().toIso8601String().substring(0, 16)} · ${a.topics.join(',')} · ${a.evidenceSignals.join(',')}');
  }
  final bySource = <String, int>{};
  for (final a in picks) {
    bySource[a.sourceId] = (bySource[a.sourceId] ?? 0) + 1;
  }
  print('--- picks per source: $bySource');
  client.close();
  await db.close();
}

// ignore_for_file: avoid_print
// Dev tool: runs the real fetch-on-open pipeline against the live feeds (not part of the tests).
//
//   cd app && dart run tool/live_ingest.dart
//
// Fetches every bundled source twice into an in-memory database and prints per-source results,
// so you can check parsing against real-world feeds and see that a rerun adds nothing new.
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:good_news/data/db/app_database.dart';
import 'package:good_news/data/http/feed_fetcher.dart';
import 'package:good_news/data/sources/direct_rss_story_source.dart';
import 'package:good_news/domain/source.dart';
import 'package:good_news/ingestion/ingestion_service.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final json = jsonDecode(File('assets/sources.json').readAsStringSync()) as Map<String, dynamic>;
  final sources = (json['sources'] as List).map((s) => Source.fromJson(s as Map<String, dynamic>)).toList();
  final db = AppDatabase(NativeDatabase.memory());
  final client = http.Client();
  final service = IngestionService(
    db: db,
    storySource: DirectRssStorySource(FeedFetcher(client)),
    deadline: const Duration(seconds: 30),
  );
  await db.upsertBundledSources(sources);

  for (final pass in [1, 2]) {
    final sw = Stopwatch()..start();
    final report = await service.refresh(force: true);
    print('--- pass $pass: ${sw.elapsedMilliseconds} ms, ${report.totalNew} new, ${report.failed} failed');
    for (final o in report.outcomes) {
      print('${o.sourceId.padRight(24)} ${o.status.name.padRight(12)} seen=${o.itemsSeen} '
          'new=${o.itemsNew} skipped=${o.itemsSkipped} ${o.error ?? ''}');
    }
  }
  final rows = await db.latestArticles(limit: 5);
  print('--- total stored: ${await db.articleCount()}; newest:');
  for (final a in rows) {
    print('${a.publishedAt.toUtc().toIso8601String()}  ${a.title}  [${a.topics.join(',')}]');
    print('    ${a.excerpt.length > 110 ? '${a.excerpt.substring(0, 110)}…' : a.excerpt}');
  }
  client.close();
  await db.close();
}

// ignore_for_file: avoid_print
// Static feed exporter (web milestone). Fetches the curated feeds with the same code the Android
// app uses, classifies with the bundled rules, and writes docs/static-feed-contract.md files.
//
//   cd app && dart run tool/export_static.dart --out build/feed/v1
//
// Options: --out <dir> (default build/feed/v1), --days <n> (default 14).
// Exit code 1 (and the output folder is left untouched) if too few sources could be read.
import 'dart:convert';
import 'dart:io';

import 'package:good_news/data/db/app_database.dart' show articleIdFor;
import 'package:good_news/data/http/feed_fetcher.dart';
import 'package:good_news/data/sources/direct_rss_story_source.dart';
import 'package:good_news/domain/source.dart';
import 'package:good_news/pipeline/classifier.dart';
import 'package:good_news/pipeline/rules.dart';
import 'package:good_news/web/static_feed.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  String arg(String name, String fallback) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback;
  }

  final out = Directory(arg('out', 'build/feed/v1'));
  final days = int.parse(arg('days', '14'));
  final json = jsonDecode(File('assets/sources.json').readAsStringSync()) as Map<String, dynamic>;
  final sources = (json['sources'] as List).map((s) => Source.fromJson(s as Map<String, dynamic>)).toList();
  final rules = Rules.parse(File('assets/rules/rules.json').readAsStringSync());
  final now = DateTime.now().toUtc();

  final client = http.Client();
  final reader = DirectRssStorySource(FeedFetcher(client, userAgent: 'GoodNewsExporter/0.1 (+https://example.org/app)'));
  final articles = <FeedArticle>[];
  var failed = 0;

  Future<void> one(Source s) async {
    try {
      final result = await reader.load(s);
      for (final c in result.candidates) {
        final item = c.item;
        final classification = classify(
          ClassifierItem(
            source: s.name,
            title: item.title,
            excerpt: item.excerpt,
            url: item.canonicalUrl,
            publishedAt: item.publishedAt,
            sourceTrust: s.trustScore,
            language: item.language,
          ),
          rules,
          now: now,
        );
        articles.add(FeedArticle(id: articleIdFor(item.canonicalUrl), sourceId: s.id, item: item, classification: classification));
      }
      print('${s.id.padRight(24)} ok     ${result.candidates.length} items');
    } catch (e) {
      failed++;
      print('${s.id.padRight(24)} FAILED $e');
    }
  }

  // Four at a time, like the app.
  final queue = List.of(sources);
  await Future.wait([
    for (var i = 0; i < 4; i++)
      () async {
        while (queue.isNotEmpty) {
          await one(queue.removeAt(0));
        }
      }(),
  ]);
  client.close();

  if (failed * 2 > sources.length || articles.isEmpty) {
    stderr.writeln('Only ${sources.length - failed}/${sources.length} sources could be read: not writing a feed.');
    exit(1);
  }

  final feed = buildStaticFeed(articles: articles, sources: sources, rulesVersion: rules.version, now: now, keepDays: days);
  final staging = Directory('${out.path}.tmp');
  if (staging.existsSync()) staging.deleteSync(recursive: true);
  for (final entry in feed.files.entries) {
    final file = File('${staging.path}/${entry.key}')..createSync(recursive: true);
    file.writeAsStringSync(const JsonEncoder.withIndent(' ').convert(entry.value));
  }
  if (out.existsSync()) out.deleteSync(recursive: true);
  out.parent.createSync(recursive: true);
  staging.renameSync(out.path);

  final manifest = feed.files['manifest.json']! as Map;
  print('--- wrote ${out.path}: ${manifest['count']} stories in ${(manifest['articles'] as List).length} day files '
      '(${articles.length} read; excluded, duplicate and older than $days days left out)');
}

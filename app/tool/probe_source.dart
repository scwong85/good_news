// ignore_for_file: avoid_print
// Dev tool: how would a candidate feed do under the current rules? Not part of the tests.
//
//   cd app && dart run tool/probe_source.dart <name> <rss_url> [trust_score]
//
// Fetches the feed like the app does, classifies every item with the bundled rules and prints
// the route counts and each item (for the manual review the source policy requires).
import 'dart:io';

import 'package:good_news/data/http/feed_fetcher.dart';
import 'package:good_news/data/sources/direct_rss_story_source.dart';
import 'package:good_news/domain/source.dart';
import 'package:good_news/pipeline/classifier.dart';
import 'package:good_news/pipeline/rules.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final name = args[0];
  final trust = args.length > 2 ? double.parse(args[2]) : 0.7;
  final source = Source(id: 'probe', name: name, homepageUrl: args[1], rssUrl: args[1], tier: 1, trustScore: trust, language: 'en', regions: const ['global']);
  final rules = Rules.parse(File('assets/rules/rules.json').readAsStringSync());
  final client = http.Client();
  final result = await DirectRssStorySource(FeedFetcher(client)).load(source);
  client.close();
  final counts = <String, int>{};
  final lines = <String>[];
  for (final c in result.candidates) {
    final i = c.item;
    final k = classify(
      ClassifierItem(source: name, title: i.title, excerpt: i.excerpt, url: i.canonicalUrl, publishedAt: i.publishedAt, sourceTrust: trust, language: i.language),
      rules,
      now: DateTime.now().toUtc(),
    );
    counts[k.route] = (counts[k.route] ?? 0) + 1;
    lines.add('${k.route.padRight(8)} ${k.score.toStringAsFixed(2)}  ${i.title}${k.route == routeExcluded ? "   [${k.reason}]" : ""}');
  }
  print('$name: ${result.candidates.length} items  $counts');
  lines.forEach(print);
}

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:good_news/data/db/app_database.dart';
import 'package:good_news/data/http/feed_fetcher.dart';
import 'package:good_news/data/sources/direct_rss_story_source.dart';
import 'package:good_news/domain/source.dart' as domain;
import 'package:good_news/classification/classification_service.dart';
import 'package:good_news/ingestion/ingestion_service.dart';
import 'package:good_news/pipeline/classifier.dart';
import 'package:good_news/pipeline/normalize.dart';
import 'package:good_news/pipeline/rules.dart';
import 'package:good_news/selection/dedupe_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Mutable clock shared by the service and the story source.
class FakeClock {
  FakeClock([DateTime? start]) : value = start ?? DateTime.utc(2026, 10, 27, 12);
  DateTime value;
  DateTime call() => value;
  void advance(Duration d) => value = value.add(d);
}

domain.Source source(String id) => domain.Source(
      id: id,
      name: 'Source $id',
      homepageUrl: 'https://$id.example.com',
      rssUrl: 'https://$id.example.com/feed/',
      tier: 1,
      trustScore: 0.9,
      language: 'en',
      regions: const ['global'],
    );

String pubDate(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String two(int n) => n.toString().padLeft(2, '0');
  final u = d.toUtc();
  return '${days[u.weekday - 1]}, ${two(u.day)} ${months[u.month - 1]} ${u.year} ${two(u.hour)}:${two(u.minute)}:${two(u.second)} +0000';
}

String rssItem(String title, String link, DateTime when, {String desc = 'Short description.'}) =>
    '<item><title>$title</title><link>$link</link><guid>$link</guid><pubDate>${pubDate(when)}</pubDate>'
    '<description><![CDATA[$desc]]></description></item>';

List<int> rss(Iterable<String> items) => utf8.encode(
    '<?xml version="1.0"?><rss version="2.0"><channel><title>T</title>${items.join()}</channel></rss>');

/// Everything a service test needs, backed by in-memory SQLite and a routable fake web.
class Harness {
  Harness({
    required this.routes,
    Duration ttl = const Duration(minutes: 30),
    int concurrency = 4,
    Duration deadline = const Duration(seconds: 5),
    int retentionDays = 30,
    bool classify = false,
    List<Future<Object?> Function()> extraHooks = const [],
  }) {
    db = AppDatabase(NativeDatabase.memory());
    client = MockClient((request) async {
      requests.add(request);
      final handler = routes[request.url.host.split('.').first];
      if (handler == null) return http.Response('no route', 404);
      return handler(request);
    });
    final fetcher = FeedFetcher(client,
        retryBackoff: Duration.zero, timeout: const Duration(seconds: 2), sleep: (_) async {});
    if (classify) {
      classification = ClassificationService(db, loadRules(), now: clock.call);
    }
    service = IngestionService(
      db: db,
      classification: classification,
      afterRefresh: [
        if (classification != null) classification!.reclassifyOutdated,
        if (classify) DedupeService(db, now: clock.call).refreshClusters,
        ...extraHooks,
      ],
      storySource: DirectRssStorySource(fetcher, now: clock.call),
      now: clock.call,
      ttl: ttl,
      concurrency: concurrency,
      deadline: deadline,
      retentionDays: retentionDays,
    );
  }

  /// Handlers keyed by the first host label, e.g. `a` for https://a.example.com/feed/.
  final Map<String, Future<http.Response> Function(http.BaseRequest)> routes;
  final clock = FakeClock();
  final requests = <http.BaseRequest>[];
  late final AppDatabase db;
  ClassificationService? classification;
  late final http.Client client;
  late final IngestionService service;

  Future<void> addSources(List<String> ids) => db.upsertBundledSources(ids.map(source).toList());
  int requestsTo(String id) => requests.where((r) => r.url.host.startsWith('$id.')).length;
  Future<void> close() => db.close();
}

Future<http.Response> feed(List<int> body, {Map<String, String> headers = const {}}) async =>
    http.Response.bytes(body, 200, headers: headers);

Rules loadRules() => Rules.parse(File('assets/rules/rules.json').readAsStringSync());

/// Inserts one already-classified article (bypassing feeds), for selection tests.
Future<String> addArticle(
  AppDatabase db,
  String sourceId, {
  required String slug,
  String? title,
  String route = 'today',
  double score = 0.6,
  DateTime? publishedAt,
  List<String> topics = const ['environment'],
  DateTime? fetchedAt,
}) async {
  final url = 'https://$sourceId.example.com/$slug';
  await db.insertNewArticles(
    sourceId,
    [
      NormalizedItem(
        externalId: url,
        canonicalUrl: url,
        title: title ?? 'Story $slug',
        excerpt: 'Excerpt $slug',
        publishedAt: publishedAt ?? DateTime.utc(2026, 10, 27, 10),
        language: 'en',
        regions: const ['global'],
        topics: const [],
      ),
    ],
    fetchedAt ?? DateTime.utc(2026, 10, 27, 11),
    classifications: {
      url: Classification(route: route, score: score, rulesVersion: 'test', topics: topics),
    },
  );
  return articleIdFor(url);
}

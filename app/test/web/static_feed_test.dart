import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/data/sources/static_json_story_source.dart';
import 'package:good_news/data/http/feed_fetcher.dart' show FetchFailure;
import 'package:good_news/pipeline/classifier.dart';
import 'package:good_news/pipeline/normalize.dart';
import 'package:good_news/web/static_feed.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../ingestion/test_support.dart' show source;

FeedArticle article(String slug, DateTime at, {String route = routeToday, String sourceId = 'a', String excerpt = 'Short.'}) {
  final url = 'https://$sourceId.example.com/$slug';
  return FeedArticle(
    id: slug.padRight(16, '0').substring(0, 16),
    sourceId: sourceId,
    item: NormalizedItem(
      externalId: url,
      canonicalUrl: url,
      title: 'Headline $slug',
      excerpt: excerpt,
      publishedAt: at,
      language: 'en',
      regions: const ['global'],
      topics: const ['science'],
    ),
    classification: Classification(route: route, score: route == routeExcluded ? 0 : 0.8, rulesVersion: '2026.11.2', topics: const ['science']),
  );
}

void main() {
  final now = DateTime.utc(2026, 10, 28, 6);

  group('buildStaticFeed', () {
    test('groups by UTC publish day, newest first, with a manifest', () {
      final feed = buildStaticFeed(
        articles: [
          article('old', DateTime.utc(2026, 10, 27, 9)),
          article('new', DateTime.utc(2026, 10, 28, 5)),
          article('newer', DateTime.utc(2026, 10, 28, 5, 30)),
        ],
        sources: [source('a')],
        rulesVersion: '2026.11.2',
        now: now,
      );
      expect(feed.files.keys, containsAll(['manifest.json', 'sources.json', 'articles/2026-10-28.json', 'articles/2026-10-27.json']));
      final manifest = StaticManifest.fromJson(feed.files['manifest.json']);
      expect(manifest.articles, ['articles/2026-10-28.json', 'articles/2026-10-27.json']);
      expect(manifest.count, 3);
      expect(manifest.rulesVersion, '2026.11.2');
      final day = feed.files['articles/2026-10-28.json']! as Map;
      expect([for (final a in day['articles'] as List) (a as Map)['title']], ['Headline newer', 'Headline new']);
    });

    test('leaves out excluded stories, duplicates and days beyond the retention window', () {
      final feed = buildStaticFeed(
        articles: [
          article('ok', DateTime.utc(2026, 10, 28, 1)),
          article('ok', DateTime.utc(2026, 10, 28, 1)),
          article('bad', DateTime.utc(2026, 10, 28, 2), route: routeExcluded),
          article('ancient', DateTime.utc(2026, 9, 1)),
        ],
        sources: [source('a')],
        rulesVersion: 'v',
        now: now,
      );
      expect(StaticManifest.fromJson(feed.files['manifest.json']).count, 1);
      expect(feed.files.containsKey('articles/2026-09-01.json'), isFalse);
      expect(jsonEncode(feed.files), isNot(contains('Headline bad')));
    });

    test('the feed never carries more than the excerpt and lists no article bodies', () {
      final feed = buildStaticFeed(articles: [article('x', DateTime.utc(2026, 10, 28, 1))], sources: [source('a')], rulesVersion: 'v', now: now);
      final a = ((feed.files['articles/2026-10-28.json']! as Map)['articles'] as List).single as Map;
      expect(a.keys, containsAll(['id', 'source_id', 'canonical_url', 'title', 'excerpt', 'published_at', 'route', 'explanation', 'rules_version']));
      expect(a.keys, isNot(contains('content')));
      expect(a.keys, isNot(contains('body')));
    });

    test('sources.json lists only public attribution data', () {
      final feed = buildStaticFeed(articles: const [], sources: [source('a')], rulesVersion: 'v', now: now);
      final s = ((feed.files['sources.json']! as Map)['sources'] as List).single as Map;
      expect(s.keys, isNot(contains('rss_url')));
      expect(s['name'], 'Source a');
    });
  });

  group('reading', () {
    test('a manifest with another schema is rejected; stale after 48 hours', () {
      expect(() => StaticManifest.fromJson({'schema': 2}), throwsFormatException);
      final m = StaticManifest.fromJson({'schema': 1, 'generated_at': '2026-10-26T05:00:00Z', 'rules_version': 'v', 'articles': [], 'count': 0});
      expect(m.isStale(DateTime.utc(2026, 10, 28, 4)), isFalse);
      expect(m.isStale(DateTime.utc(2026, 10, 28, 6)), isTrue);
    });

    test('unusable entries are skipped, not fatal; over-long excerpts are cut', () {
      expect(normalizedItemFromJson('nope'), isNull);
      expect(normalizedItemFromJson({'canonical_url': 'javascript:alert(1)', 'title': 't', 'published_at': '2026-10-28T00:00:00Z'}), isNull);
      expect(normalizedItemFromJson({'canonical_url': 'https://a/x', 'title': '  ', 'published_at': '2026-10-28T00:00:00Z'}), isNull);
      expect(normalizedItemFromJson({'canonical_url': 'https://a/x', 'title': 't', 'published_at': 'garbage'}), isNull);
      final long = normalizedItemFromJson({'canonical_url': 'https://a/x', 'title': 't', 'published_at': '2026-10-28T00:00:00Z', 'excerpt': 'word ' * 200})!;
      expect(long.excerpt.runes.length, lessThanOrEqualTo(excerptMaxChars));
    });
  });

  group('StaticJsonStorySource', () {
    final base = Uri.parse('https://example.org/good_news/feed/v1/');
    late List<Uri> requests;

    http.Client web(StaticFeedFiles feed, {Set<String> missing = const {}}) {
      requests = [];
      return MockClient((req) async {
        requests.add(req.url);
        final path = req.url.path.replaceFirst('/good_news/feed/v1/', '');
        if (missing.contains(path) || !feed.files.containsKey(path)) return http.Response('nope', 404);
        return http.Response(jsonEncode(feed.files[path]), 200, headers: {'content-type': 'application/json'});
      });
    }

    final feed = buildStaticFeed(
      articles: [
        article('a1', DateTime.utc(2026, 10, 28, 5), sourceId: 'a'),
        article('b1', DateTime.utc(2026, 10, 28, 4), sourceId: 'b'),
        article('a2', DateTime.utc(2026, 10, 27, 4), sourceId: 'a'),
      ],
      sources: [source('a'), source('b')],
      rulesVersion: '2026.11.2',
      now: now,
    );

    test('each source gets only its own stories; the manifest is read once per refresh', () async {
      StaticManifest? seen;
      final s = StaticJsonStorySource(web(feed), base, now: () => now, onManifest: (m) => seen = m);
      final a = await s.load(source('a'));
      final b = await s.load(source('b'));
      expect(a.candidates.map((c) => c.item.title), ['Headline a1', 'Headline a2']);
      expect(b.candidates.map((c) => c.item.title), ['Headline b1']);
      expect(requests.where((u) => u.path.endsWith('manifest.json')), hasLength(1));
      expect(seen!.generatedAt, now);
      expect(requests.where((u) => u.path.contains('articles/')).every((u) => u.queryParameters.containsKey('v')), isTrue);
    });

    test('a missing day file does not hide the other days', () async {
      final s = StaticJsonStorySource(web(feed, missing: {'articles/2026-10-27.json'}), base, now: () => now);
      expect((await s.load(source('a'))).candidates.map((c) => c.item.title), ['Headline a1']);
    });

    test('an unreachable or broken feed is a source failure, and is retried next time', () async {
      var up = false;
      final inner = web(feed);
      final s = StaticJsonStorySource(
        MockClient((r) async => up ? inner.get(r.url) : http.Response('down', 503)),
        base,
        now: () => now,
        manifestTtl: Duration.zero,
      );
      await expectLater(s.load(source('a')), throwsA(isA<FetchFailure>()));
      up = true;
      expect((await s.load(source('a'))).candidates, isNotEmpty);
    });
  });
}

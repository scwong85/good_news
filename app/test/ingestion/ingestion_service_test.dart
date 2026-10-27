import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/ingestion/ingestion_service.dart';
import 'package:http/http.dart' as http;

import 'test_support.dart';

void main() {
  late Harness h;
  tearDown(() => h.close());

  DateTime ago(Duration d) => h.clock.value.subtract(d);

  List<int> twoItems(String id) => rss([
        rssItem('Story one from $id', 'https://$id.example.com/one?utm_source=x', ago(const Duration(hours: 3))),
        rssItem('Story two from $id', 'https://$id.example.com/two', ago(const Duration(hours: 5))),
      ]);

  group('refresh', () {
    test('fetches all enabled sources and stores their articles', () async {
      h = Harness(routes: {
        'a': (_) => feed(twoItems('a'), headers: {'etag': '"a1"'}),
        'b': (_) => feed(twoItems('b')),
      });
      await h.addSources(['a', 'b']);
      final report = await h.service.refresh();
      expect(report.outcomes.map((o) => o.status), everyElement(SourceStatus.ok));
      expect(report.totalNew, 4);
      expect(await h.db.articleCount(), 4);
      final a = (await h.db.allSources()).firstWhere((s) => s.id == 'a');
      expect((a.etag, a.lastStatus, a.consecutiveFailures), ('"a1"', 'ok', 0));
      expect(a.lastFetchedAt!.toUtc(), h.clock.value);
      final titles = (await h.db.latestArticles()).map((r) => r.canonicalUrl);
      expect(titles, contains('https://a.example.com/one')); // tracking param stripped
    });

    test('a rerun creates no duplicates', () async {
      h = Harness(routes: {'a': (_) => feed(twoItems('a'))});
      await h.addSources(['a']);
      await h.service.refresh();
      final again = await h.service.refresh(force: true);
      expect(again.totalNew, 0);
      expect(again.outcomeFor('a')!.itemsNew, 0);
      expect(await h.db.articleCount(), 2);
    });

    test('the same story in two sources is stored once', () async {
      final shared = rss([rssItem('Shared', 'https://shared.example.com/s', ago(const Duration(hours: 1)))]);
      h = Harness(routes: {'a': (_) => feed(shared), 'b': (_) => feed(shared)});
      await h.addSources(['a', 'b']);
      final report = await h.service.refresh();
      expect(report.totalNew, 1);
      expect(await h.db.articleCount(), 1);
    });

    test('failures are isolated: one bad source never blocks the others', () async {
      h = Harness(routes: {
        'a': (_) => feed(twoItems('a')),
        'b': (_) async => http.Response('boom', 500),
        'c': (_) => feed('<<< not xml'.codeUnits),
        'd': (_) => feed('<html><body>hi</body></html>'.codeUnits),
        'e': (_) async => throw http.ClientException('offline'),
      });
      await h.addSources(['a', 'b', 'c', 'd', 'e']);
      final report = await h.service.refresh();
      expect(report.outcomeFor('a')!.status, SourceStatus.ok);
      for (final id in ['b', 'c', 'd', 'e']) {
        expect(report.outcomeFor(id)!.status, SourceStatus.failed, reason: id);
        expect(report.outcomeFor(id)!.error, isNotEmpty);
      }
      expect(report.failed, 4);
      expect(await h.db.articleCount(), 2);
      final rows = {for (final s in await h.db.allSources()) s.id: s};
      expect(rows['b']!.lastStatus, startsWith('error: HTTP 500'));
      expect(rows['b']!.consecutiveFailures, 1);
      expect(rows['a']!.consecutiveFailures, 0);
    });

    test('offline start keeps the cache and reports failures', () async {
      var online = true;
      h = Harness(routes: {
        'a': (_) async {
          if (!online) throw http.ClientException('no network');
          return feed(twoItems('a'));
        }
      });
      await h.addSources(['a']);
      await h.service.refresh();
      online = false;
      h.clock.advance(const Duration(hours: 1));
      final report = await h.service.refresh();
      expect(report.failed, 1);
      expect(await h.db.articleCount(), 2); // cache intact
    });

    test('bad items are skipped, good ones kept', () async {
      h = Harness(routes: {
        'a': (_) => feed(rss([
              rssItem('Good', 'https://a.example.com/good', ago(const Duration(hours: 1))),
              '<item><title>No date</title><link>https://a.example.com/nodate</link></item>',
              rssItem('Bad scheme', 'ftp://a.example.com/x', ago(const Duration(hours: 1))),
            ]))
      });
      await h.addSources(['a']);
      final o = (await h.service.refresh()).outcomeFor('a')!;
      expect((o.itemsSeen, o.itemsNew, o.itemsSkipped), (3, 1, 2));
    });

    test('items older than the retention window are not stored', () async {
      h = Harness(retentionDays: 30, routes: {
        'a': (_) => feed(rss([
              rssItem('Ancient', 'https://a.example.com/old', ago(const Duration(days: 90))),
              rssItem('Recent', 'https://a.example.com/new', ago(const Duration(days: 2))),
            ]))
      });
      await h.addSources(['a']);
      final o = (await h.service.refresh()).outcomeFor('a')!;
      expect(o.itemsNew, 1);
      expect((await h.db.latestArticles()).single.title, 'Recent');
    });

    test('previously stored articles are pruned once they age out', () async {
      h = Harness(retentionDays: 30, routes: {
        'a': (_) => feed(rss([rssItem('Will age', 'https://a.example.com/age', ago(const Duration(days: 20)))]))
      });
      await h.addSources(['a']);
      await h.service.refresh();
      h.clock.advance(const Duration(days: 20)); // the article is now 40 days old
      await h.service.refresh(force: true);
      expect(await h.db.articleCount(), 0);
    });
  });

  group('before_fetch rules', () {
    test('disabled sources are never requested', () async {
      h = Harness(routes: {'a': (_) => feed(twoItems('a')), 'b': (_) => feed(twoItems('b'))});
      await h.addSources(['a', 'b']);
      await h.db.setSourceEnabled('b', false);
      await h.service.refresh(force: true);
      expect(h.requestsTo('b'), 0);
      expect(h.requestsTo('a'), 1);
    });

    test('the cache TTL prevents refetching, then allows it', () async {
      h = Harness(ttl: const Duration(minutes: 30), routes: {'a': (_) => feed(twoItems('a'))});
      await h.addSources(['a']);
      await h.service.refresh();
      h.clock.advance(const Duration(minutes: 10));
      expect((await h.service.refresh()).outcomeFor('a')!.status, SourceStatus.skippedFresh);
      expect(h.requestsTo('a'), 1);
      h.clock.advance(const Duration(minutes: 25));
      expect((await h.service.refresh()).outcomeFor('a')!.status, SourceStatus.ok);
      expect(h.requestsTo('a'), 2);
    });

    test('force ignores the TTL', () async {
      h = Harness(routes: {'a': (_) => feed(twoItems('a'))});
      await h.addSources(['a']);
      await h.service.refresh();
      await h.service.refresh(force: true);
      expect(h.requestsTo('a'), 2);
    });

    test('conditional GET: sends the validators and handles 304', () async {
      var call = 0;
      h = Harness(routes: {
        'a': (req) async {
          if (call++ == 0) return feed(twoItems('a'), headers: {'etag': '"v1"', 'last-modified': 'lm1'});
          expect(req.headers['If-None-Match'], '"v1"');
          expect(req.headers['If-Modified-Since'], 'lm1');
          return http.Response('', 304);
        }
      });
      await h.addSources(['a']);
      await h.service.refresh();
      h.clock.advance(const Duration(hours: 1));
      final o = (await h.service.refresh()).outcomeFor('a')!;
      expect(o.status, SourceStatus.notModified);
      expect(await h.db.articleCount(), 2);
      final row = (await h.db.allSources()).single;
      expect((row.etag, row.lastStatus), ('"v1"', 'not_modified'));
    });

    test('force drops the validators', () async {
      h = Harness(routes: {'a': (req) {
        return feed(twoItems('a'), headers: {'etag': '"v1"'});
      }});
      await h.addSources(['a']);
      await h.service.refresh();
      await h.service.refresh(force: true);
      expect(h.requests.last.headers.containsKey('If-None-Match'), isFalse);
    });
  });

  group('backoff', () {
    test('three consecutive failures start an exponential backoff; success resets it', () async {
      var fail = true;
      h = Harness(routes: {
        'a': (_) async => fail ? http.Response('boom', 500) : await feed(twoItems('a')),
      });
      await h.addSources(['a']);
      for (var i = 0; i < 3; i++) {
        h.clock.advance(const Duration(hours: 1));
        await h.service.refresh();
      }
      var row = (await h.db.allSources()).single;
      expect(row.consecutiveFailures, 3);
      expect(row.backoffUntil!.toUtc(), h.clock.value.add(const Duration(minutes: 15)));

      // Inside the backoff window the source is skipped without a request.
      final before = h.requestsTo('a');
      h.clock.advance(const Duration(minutes: 5));
      expect((await h.service.refresh()).outcomeFor('a')!.status, SourceStatus.skippedBackoff);
      expect(h.requestsTo('a'), before);

      // After it, a success clears everything.
      fail = false;
      h.clock.advance(const Duration(minutes: 20));
      expect((await h.service.refresh()).outcomeFor('a')!.status, SourceStatus.ok);
      row = (await h.db.allSources()).single;
      expect((row.consecutiveFailures, row.backoffUntil), (0, null));
    });

    test('the fourth failure doubles the backoff, capped at six hours', () async {
      h = Harness(routes: {'a': (_) async => http.Response('boom', 500)});
      await h.addSources(['a']);
      for (var i = 0; i < 4; i++) {
        h.clock.advance(const Duration(days: 1));
        await h.service.refresh();
      }
      var row = (await h.db.allSources()).single;
      expect(row.backoffUntil!.toUtc(), h.clock.value.add(const Duration(minutes: 30)));
      for (var i = 0; i < 10; i++) {
        h.clock.advance(const Duration(days: 1));
        await h.service.refresh();
      }
      row = (await h.db.allSources()).single;
      expect(row.backoffUntil!.toUtc(), h.clock.value.add(const Duration(hours: 6)));
    });

    test('429 with Retry-After backs the source off for that long', () async {
      h = Harness(routes: {
        'a': (_) async => http.Response('slow', 429, headers: {'retry-after': '600'}),
      });
      await h.addSources(['a']);
      await h.service.refresh();
      final row = (await h.db.allSources()).single;
      expect(row.consecutiveFailures, 1);
      expect(row.backoffUntil!.toUtc(), h.clock.value.add(const Duration(seconds: 600)));
      expect((await h.service.refresh()).outcomeFor('a')!.status, SourceStatus.skippedBackoff);
    });

    test('force ignores the backoff', () async {
      h = Harness(routes: {'a': (_) async => http.Response('slow', 429, headers: {'retry-after': '600'})});
      await h.addSources(['a']);
      await h.service.refresh();
      final before = h.requestsTo('a');
      await h.service.refresh(force: true);
      expect(h.requestsTo('a'), before + 1);
    });
  });

  group('concurrency and deadline', () {
    test('never runs more fetches at once than the limit', () async {
      var running = 0;
      var peak = 0;
      Future<http.Response> slow(String id) async {
        running++;
        peak = running > peak ? running : peak;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        running--;
        return feed(twoItems(id));
      }

      final ids = ['a', 'b', 'c', 'd', 'e', 'f'];
      h = Harness(concurrency: 2, routes: {for (final id in ids) id: (_) => slow(id)});
      await h.addSources(ids);
      final report = await h.service.refresh();
      expect(report.outcomes.map((o) => o.status), everyElement(SourceStatus.ok));
      expect(peak, 2);
    });

    test('a hanging source cannot block the refresh past the deadline', () async {
      final never = Completer<http.Response>();
      h = Harness(deadline: const Duration(milliseconds: 150), routes: {
        'a': (_) => feed(twoItems('a')),
        'b': (_) => never.future,
      });
      await h.addSources(['a', 'b']);
      final sw = Stopwatch()..start();
      final report = await h.service.refresh();
      expect(sw.elapsedMilliseconds, lessThan(1500));
      expect(report.outcomeFor('a')!.status, SourceStatus.ok);
      expect(report.outcomeFor('b')!.status, SourceStatus.deadline);
      expect(await h.db.articleCount(), 2); // the finished source's results are kept
    });
  });
}

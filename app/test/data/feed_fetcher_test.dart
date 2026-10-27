import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/data/http/feed_fetcher.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final url = Uri.parse('https://example.com/feed/');

http.Response ok(String body, {Map<String, String> headers = const {}}) =>
    http.Response.bytes(utf8.encode(body), 200, headers: headers);

FeedFetcher fetcher(MockClient client, {int maxBytes = 1024, Duration? timeout, List<Duration>? sleeps}) =>
    FeedFetcher(
      client,
      maxBytes: maxBytes,
      timeout: timeout ?? const Duration(seconds: 5),
      sleep: (d) async => sleeps?.add(d),
    );

void main() {
  test('success returns bytes, ETag and Last-Modified', () async {
    final f = fetcher(MockClient((_) async =>
        ok('<rss/>', headers: {'etag': '"v1"', 'last-modified': 'Tue, 27 Oct 2026 07:00:00 GMT'})));
    final r = await f.fetch(url);
    expect(utf8.decode(r.bytes), '<rss/>');
    expect((r.etag, r.lastModified), ('"v1"', 'Tue, 27 Oct 2026 07:00:00 GMT'));
    expect(r.notModified, isFalse);
  });

  test('sends User-Agent and conditional headers', () async {
    late http.BaseRequest seen;
    final f = fetcher(MockClient((req) async {
      seen = req;
      return http.Response('', 304);
    }));
    final r = await f.fetch(url, etag: '"v1"', lastModified: 'lm');
    expect(seen.headers['User-Agent'], contains('GoodNewsApp'));
    expect(seen.headers['If-None-Match'], '"v1"');
    expect(seen.headers['If-Modified-Since'], 'lm');
    expect(r.notModified, isTrue);
    expect(r.etag, '"v1"'); // carried over so the caller keeps its validators
  });

  test('no conditional headers when none are known', () async {
    late http.BaseRequest seen;
    await fetcher(MockClient((req) async {
      seen = req;
      return ok('x');
    })).fetch(url);
    expect(seen.headers.containsKey('If-None-Match'), isFalse);
    expect(seen.headers.containsKey('If-Modified-Since'), isFalse);
  });

  test('4xx fails immediately without retrying', () async {
    var calls = 0;
    final f = fetcher(MockClient((_) async {
      calls++;
      return http.Response('nope', 404);
    }));
    await expectLater(f.fetch(url), throwsA(isA<FetchFailure>().having((e) => e.httpStatus, 'status', 404)));
    expect(calls, 1);
  });

  test('5xx is retried once, then fails', () async {
    var calls = 0;
    final sleeps = <Duration>[];
    final f = fetcher(MockClient((_) async {
      calls++;
      return http.Response('boom', 503);
    }), sleeps: sleeps);
    await expectLater(f.fetch(url), throwsA(isA<FetchFailure>().having((e) => e.httpStatus, 'status', 503)));
    expect(calls, 2);
    expect(sleeps, hasLength(1));
  });

  test('a transient error recovers on retry', () async {
    var calls = 0;
    final f = fetcher(MockClient((_) async {
      if (calls++ == 0) throw http.ClientException('connection reset');
      return ok('<rss/>');
    }));
    expect(utf8.decode((await f.fetch(url)).bytes), '<rss/>');
    expect(calls, 2);
  });

  test('network failure surfaces as FetchFailure', () async {
    final f = fetcher(MockClient((_) async => throw http.ClientException('down')));
    await expectLater(f.fetch(url), throwsA(isA<FetchFailure>().having((e) => e.message, 'message', contains('network error'))));
  });

  test('429 is not retried and carries Retry-After', () async {
    var calls = 0;
    final f = fetcher(MockClient((_) async {
      calls++;
      return http.Response('slow down', 429, headers: {'retry-after': '120'});
    }));
    await expectLater(
      f.fetch(url),
      throwsA(isA<FetchFailure>()
          .having((e) => e.httpStatus, 'status', 429)
          .having((e) => e.retryAfter, 'retryAfter', const Duration(seconds: 120))),
    );
    expect(calls, 1);
  });

  test('Retry-After in HTTP-date form is ignored; huge values are capped', () async {
    Future<Duration?> retryAfter(String value) async {
      final f = fetcher(MockClient((_) async => http.Response('', 429, headers: {'retry-after': value})));
      try {
        await f.fetch(url);
      } on FetchFailure catch (e) {
        return e.retryAfter;
      }
      return null;
    }

    expect(await retryAfter('Wed, 21 Oct 2026 07:28:00 GMT'), isNull);
    expect(await retryAfter('999999999'), const Duration(days: 1));
  });

  test('body larger than the cap fails (streamed, without trusting headers)', () async {
    final f = fetcher(MockClient.streaming((req, _) async => http.StreamedResponse(
          Stream.fromIterable([List.filled(700, 65), List.filled(700, 65)]),
          200,
        )));
    await expectLater(f.fetch(url), throwsA(isA<FetchFailure>().having((e) => e.message, 'message', contains('larger than'))));
  });

  test('declared Content-Length over the cap fails before reading', () async {
    final f = fetcher(MockClient.streaming((req, _) async => http.StreamedResponse(
          const Stream.empty(),
          200,
          contentLength: 999999,
        )));
    await expectLater(f.fetch(url), throwsA(isA<FetchFailure>().having((e) => e.message, 'message', contains('larger than'))));
  });

  test('a hanging server times out (and the timeout is retried once)', () async {
    var calls = 0;
    final f = fetcher(MockClient((_) {
      calls++;
      return Completer<http.Response>().future;
    }), timeout: const Duration(milliseconds: 50));
    await expectLater(f.fetch(url), throwsA(isA<FetchFailure>().having((e) => e.message, 'message', contains('timeout'))));
    expect(calls, 2);
  });

  test('a body that stalls mid-stream times out', () async {
    final f = fetcher(MockClient.streaming((req, _) async {
      final controller = StreamController<List<int>>()..add([1, 2, 3]);
      return http.StreamedResponse(controller.stream, 200);
    }), timeout: const Duration(milliseconds: 50));
    await expectLater(f.fetch(url), throwsA(isA<FetchFailure>().having((e) => e.message, 'message', contains('timeout'))));
  });
}

import 'dart:async';

import 'package:http/http.dart' as http;

/// A feed request failed. [retryAfter] is set for 429 responses that carry Retry-After.
class FetchFailure implements Exception {
  FetchFailure(this.message, {this.httpStatus, this.retryAfter});
  final String message;
  final int? httpStatus;
  final Duration? retryAfter;
  @override
  String toString() => 'FetchFailure($message)';
}

class FetchResult {
  FetchResult({
    required this.statusCode,
    this.bytes = const [],
    this.etag = '',
    this.lastModified = '',
    this.notModified = false,
  });
  final int statusCode;
  final List<int> bytes;
  final String etag;
  final String lastModified;
  final bool notModified;
}

/// Polite feed client: conditional GET, bounded size and time, small retry on transient errors,
/// no retry on 429 (the caller backs the source off using [FetchFailure.retryAfter]).
class FeedFetcher {
  FeedFetcher(
    this._client, {
    this.userAgent = 'GoodNewsApp/0.1 (+https://example.org/app)',
    this.timeout = const Duration(seconds: 10),
    this.maxBytes = 5 * 1024 * 1024,
    this.retries = 1,
    this.retryBackoff = const Duration(seconds: 2),
    Future<void> Function(Duration)? sleep,
  }) : _sleep = sleep ?? Future.delayed;

  final http.Client _client;
  final String userAgent;
  final Duration timeout;
  final int maxBytes;
  final int retries;
  final Duration retryBackoff;
  final Future<void> Function(Duration) _sleep;

  Future<FetchResult> fetch(Uri url, {String etag = '', String lastModified = ''}) async {
    FetchFailure? last;
    for (var attempt = 0; attempt <= retries; attempt++) {
      if (attempt > 0) await _sleep(retryBackoff * attempt);
      try {
        return await _once(url, etag, lastModified);
      } on _Transient catch (e) {
        last = e.failure;
      }
    }
    throw last!;
  }

  Future<FetchResult> _once(Uri url, String etag, String lastModified) async {
    final request = http.Request('GET', url)
      ..headers['User-Agent'] = userAgent
      ..headers['Accept'] =
          'application/rss+xml, application/atom+xml, application/xml;q=0.9, */*;q=0.5';
    if (etag.isNotEmpty) request.headers['If-None-Match'] = etag;
    if (lastModified.isNotEmpty) request.headers['If-Modified-Since'] = lastModified;

    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(timeout);
    } on TimeoutException {
      throw _Transient(FetchFailure('timeout after ${timeout.inSeconds}s'));
    } on FetchFailure {
      rethrow;
    } catch (e) {
      throw _Transient(FetchFailure('network error: ${e.runtimeType}'));
    }

    final status = response.statusCode;
    if (status == 304) {
      return FetchResult(
        statusCode: 304,
        notModified: true,
        etag: etag,
        lastModified: lastModified,
      );
    }
    if (status == 429) {
      throw FetchFailure('HTTP 429',
          httpStatus: 429, retryAfter: _parseRetryAfter(response.headers['retry-after']));
    }
    if (status >= 500) throw _Transient(FetchFailure('HTTP $status', httpStatus: status));
    if (status >= 400) throw FetchFailure('HTTP $status', httpStatus: status);

    final declared = response.contentLength ?? int.tryParse(response.headers['content-length'] ?? '');
    if (declared != null && declared > maxBytes) {
      throw FetchFailure('feed larger than $maxBytes bytes', httpStatus: status);
    }
    final bytes = <int>[];
    try {
      await for (final chunk in response.stream.timeout(timeout)) {
        bytes.addAll(chunk);
        if (bytes.length > maxBytes) {
          throw FetchFailure('feed larger than $maxBytes bytes', httpStatus: status);
        }
      }
    } on TimeoutException {
      throw _Transient(FetchFailure('timeout while reading body'));
    } on FetchFailure {
      rethrow;
    } catch (e) {
      throw _Transient(FetchFailure('network error: ${e.runtimeType}'));
    }
    return FetchResult(
      statusCode: status,
      bytes: bytes,
      etag: response.headers['etag'] ?? '',
      lastModified: response.headers['last-modified'] ?? '',
    );
  }
}

class _Transient implements Exception {
  _Transient(this.failure);
  final FetchFailure failure;
}

Duration? _parseRetryAfter(String? value) {
  if (value == null) return null;
  final seconds = int.tryParse(value.trim());
  if (seconds != null) return Duration(seconds: seconds.clamp(0, 86400));
  return null; // HTTP-date form is ignored; the caller falls back to its default backoff
}

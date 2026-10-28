import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/source.dart';
import '../../pipeline/normalize.dart';
import '../../web/static_feed.dart';
import '../http/feed_fetcher.dart' show FetchFailure;
import 'story_source.dart';

/// Web: reads the pre-built static feed (docs/static-feed-contract.md) hosted next to the app.
/// Browsers block direct feed reads, so the web build never contacts the publishers' feeds.
///
/// The manifest is fetched once per [manifestTtl] and shared by all sources of a refresh, then
/// each source picks its own stories out of the day files. Stories are re-classified locally with
/// the app's bundled rules, so the exported classification is informational only.
class StaticJsonStorySource implements StorySource {
  StaticJsonStorySource(
    this._client,
    this.feedBase, {
    DateTime Function()? now,
    this.manifestTtl = const Duration(seconds: 20),
    this.onManifest,
  }) : _now = now ?? DateTime.now;

  final http.Client _client;

  /// Folder holding `manifest.json`, with a trailing slash, e.g. `https://host/good_news/feed/v1/`.
  final Uri feedBase;
  final Duration manifestTtl;

  /// Called whenever a manifest is read, so the UI can show when the feed was generated.
  final void Function(StaticManifest manifest)? onManifest;
  final DateTime Function() _now;

  Future<_Loaded>? _loading;
  DateTime? _loadedAt;

  Future<_Loaded> _load() {
    final at = _loadedAt;
    if (_loading != null && at != null && _now().difference(at) < manifestTtl) return _loading!;
    _loadedAt = _now();
    final future = _fetchAll();
    _loading = future;
    future.then<void>((_) {}, onError: (Object _) {
      if (identical(_loading, future)) _loading = null; // retry on the next source/refresh
    });
    return future;
  }

  Future<_Loaded> _fetchAll() async {
    final manifest = StaticManifest.fromJson(await _getJson(feedBase.resolve('manifest.json')));
    onManifest?.call(manifest);
    final version = manifest.generatedAt.millisecondsSinceEpoch.toString();
    final articles = <(String, NormalizedItem)>[];
    for (final path in manifest.articles) {
      // Day files change while the day is still running; the generation time busts any cache.
      final uri = feedBase.resolve(path).replace(queryParameters: {'v': version});
      Object? json;
      try {
        json = await _getJson(uri);
      } on FetchFailure {
        continue; // one missing day file must not hide the others
      }
      if (json is! Map) continue;
      for (final raw in (json['articles'] as List? ?? const [])) {
        final item = normalizedItemFromJson(raw);
        final sourceId = raw is Map ? raw['source_id'] : null;
        if (item != null && sourceId is String) articles.add((sourceId, item));
      }
    }
    return _Loaded(manifest, articles);
  }

  Future<Object?> _getJson(Uri uri) async {
    final http.Response response;
    try {
      response = await _client.get(uri, headers: {'Cache-Control': 'no-cache'}).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw FetchFailure('static feed unreachable: ${e.runtimeType}');
    }
    if (response.statusCode != 200) {
      throw FetchFailure('static feed HTTP ${response.statusCode}', httpStatus: response.statusCode);
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw FetchFailure('static feed is not valid JSON');
    }
  }

  @override
  Future<SourceResult> load(Source source, {FetchState previous = const FetchState()}) async {
    final loaded = await _load();
    final mine = [for (final (id, item) in loaded.articles) if (id == source.id) item];
    return SourceResult(
      candidates: [for (final item in mine) Candidate(item)],
      itemsSeen: mine.length,
      etag: '',
      lastModified: '',
      httpStatus: 200,
    );
  }
}

class _Loaded {
  _Loaded(this.manifest, this.articles);
  final StaticManifest manifest;
  final List<(String, NormalizedItem)> articles;
}

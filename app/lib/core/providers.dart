import 'dart:convert';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/db/app_database.dart';
import '../data/http/feed_fetcher.dart';
import '../data/sources/direct_rss_story_source.dart';
import '../data/sources/story_source.dart';
import '../domain/source.dart';
import '../ingestion/ingestion_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(name: 'good_news'));
  ref.onDispose(db.close);
  return db;
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final storySourceProvider = Provider<StorySource>(
  (ref) => DirectRssStorySource(FeedFetcher(ref.watch(httpClientProvider))),
);

final ingestionServiceProvider = Provider<IngestionService>(
  (ref) => IngestionService(
    db: ref.watch(databaseProvider),
    storySource: ref.watch(storySourceProvider),
  ),
);

/// Loads the bundled source list (generated from docs/source-allowlist.csv).
Future<List<Source>> loadBundledSources(Future<String> Function(String) load) async {
  final json = jsonDecode(await load('assets/sources.json')) as Map<String, dynamic>;
  return (json['sources'] as List)
      .map((s) => Source.fromJson(s as Map<String, dynamic>))
      .toList();
}

final bundledSourcesProvider =
    FutureProvider<List<Source>>((ref) => loadBundledSources(rootBundle.loadString));

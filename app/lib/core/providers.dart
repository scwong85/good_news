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
import '../classification/classification_service.dart';
import '../ingestion/ingestion_service.dart';
import '../pipeline/rules.dart';
import '../selection/daily_picks_service.dart';
import '../selection/dedupe_service.dart';
import '../selection/preferences.dart';

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

/// The bundled classification rules (assets/rules/rules.json, synced from /rules).
final rulesProvider = FutureProvider<Rules>(
  // cache: false: the file is read once per app run, and a cached future would be shared across
  // app instances (tests).
  (ref) async => Rules.parse(await rootBundle.loadString('assets/rules/rules.json', cache: false)),
);

final classificationServiceProvider = FutureProvider<ClassificationService>(
  (ref) async => ClassificationService(ref.watch(databaseProvider), await ref.watch(rulesProvider.future)),
);

final dedupeServiceProvider = Provider<DedupeService>((ref) => DedupeService(ref.watch(databaseProvider)));

final preferencesRepositoryProvider =
    Provider<PreferencesRepository>((ref) => PreferencesRepository(ref.watch(databaseProvider)));

final dailyPicksServiceProvider = Provider<DailyPicksService>(
  (ref) => DailyPicksService(ref.watch(databaseProvider), ref.watch(preferencesRepositoryProvider)),
);

final ingestionServiceProvider = FutureProvider<IngestionService>((ref) async {
  final classification = await ref.watch(classificationServiceProvider.future);
  final dedupe = ref.watch(dedupeServiceProvider);
  return IngestionService(
    db: ref.watch(databaseProvider),
    storySource: ref.watch(storySourceProvider),
    classification: classification,
    afterRefresh: [classification.reclassifyOutdated, dedupe.refreshClusters],
  );
});

/// Loads the bundled source list (generated from docs/source-allowlist.csv).
Future<List<Source>> loadBundledSources(Future<String> Function(String) load) async {
  final json = jsonDecode(await load('assets/sources.json')) as Map<String, dynamic>;
  return (json['sources'] as List)
      .map((s) => Source.fromJson(s as Map<String, dynamic>))
      .toList();
}

final bundledSourcesProvider =
    FutureProvider<List<Source>>((ref) => loadBundledSources((p) => rootBundle.loadString(p, cache: false)));

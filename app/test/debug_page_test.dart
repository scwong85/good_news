import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/core/providers.dart';
import 'package:good_news/data/db/app_database.dart';
import 'package:good_news/data/http/feed_fetcher.dart';
import 'package:good_news/data/sources/direct_rss_story_source.dart';
import 'package:good_news/features/debug/ingestion_debug_page.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'ingestion/test_support.dart' as support;

void main() {
  testWidgets('opening the harness fetches feeds and lists the stored articles', (tester) async {
    final now = DateTime.now().toUtc();
    final client = MockClient((request) async {
      if (request.url.host.startsWith('ok.')) {
        return http.Response.bytes(
          support.rss([
            support.rssItem('Wetlands restored', 'https://ok.example.com/wet', now.subtract(const Duration(hours: 2))),
          ]),
          200,
        );
      }
      return http.Response('boom', 500);
    });
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final fetcher = FeedFetcher(client, retryBackoff: Duration.zero, sleep: (_) async {});

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        storySourceProvider.overrideWithValue(DirectRssStorySource(fetcher)),
        bundledSourcesProvider.overrideWith((ref) async => [support.source('ok'), support.source('bad')]),
      ],
      child: const MaterialApp(home: IngestionDebugPage()),
    ));

    // Drift and HTTP use real async, so let them run outside the fake clock.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
    await tester.pump();

    expect(find.text('Stored articles: 1'), findsOneWidget);
    expect(find.text('Wetlands restored'), findsWidgets); // in picks and in the latest list
    expect(find.textContaining("Today's picks"), findsOneWidget);
    expect(find.text('Last refresh: 1 new, 1 source(s) failed'), findsOneWidget);
    expect(find.text('Source ok'), findsOneWidget);
    expect(find.textContaining('error: HTTP 500'), findsOneWidget);
  });
}

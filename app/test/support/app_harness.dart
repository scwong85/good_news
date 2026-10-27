import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/app/app.dart';
import 'package:good_news/app/platform_services.dart';
import 'package:good_news/app/providers.dart';
import 'package:good_news/core/providers.dart';
import 'package:good_news/data/db/app_database.dart';
import 'package:good_news/data/http/feed_fetcher.dart';
import 'package:good_news/data/sources/direct_rss_story_source.dart';
import 'package:good_news/domain/source.dart';
import 'package:good_news/ingestion/ingestion_service.dart';
import 'package:good_news/selection/daily_picks_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../ingestion/test_support.dart' as support;

class FakeLinkOpener implements LinkOpener {
  final opened = <Uri>[];
  bool result = true;
  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return result;
  }
}

class FakeSharer implements Sharer {
  final shared = <({String title, Uri url})>[];
  @override
  Future<void> share({required String title, required Uri url}) async => shared.add((title: title, url: url));
}

typedef Route = Future<http.Response> Function(http.BaseRequest);

/// Stories that the real rules route to `today` (verified in the harness test).
const constructiveTitles = [
  'Wetlands restored by volunteers, study finds 40% more birds',
  'Clinic opens free care for families, study finds 30% fewer ER visits',
  'Students launch recycling partnership that cut school waste by 25%',
  'Solar farm shelters rare owls, researchers report 50% more nests',
  'City expands free bus service as ridership rises 20%, officials say',
  'Scientists develop eye drops that restore vision in trial of 120 patients',
  'Farmers adopt new irrigation method that reduced water use by 35%',
  'Volunteers plant 10,000 trees in partnership with a local university',
];

/// A whole app instance on in-memory SQLite and a fake web, for widget/integration tests.
class AppHarness {
  AppHarness({Map<String, Route>? routes, this.sourceCount = 4, this.online = true, this.deadline}) {
    this.routes = routes ?? defaultRoutes();
    db = AppDatabase(NativeDatabase.memory());
    client = MockClient((request) async {
      requests.add(request);
      if (!online) throw http.ClientException('offline');
      final handler = this.routes[request.url.host.split('.').first];
      return handler == null ? http.Response('nope', 404) : handler(request);
    });
  }

  final int sourceCount;

  /// Flip to simulate losing or regaining the network.
  bool online;

  /// Overrides the refresh deadline (the real one is 15 s).
  final Duration? deadline;
  late final Map<String, Route> routes;
  late final AppDatabase db;
  late final MockClient client;
  final requests = <http.BaseRequest>[];
  final links = FakeLinkOpener();
  final sharer = FakeSharer();

  List<Source> get sources => [for (var i = 0; i < sourceCount; i++) support.source('s$i')];

  /// Each source serves two of the constructive titles.
  Map<String, Route> defaultRoutes() {
    return {
      for (var i = 0; i < sourceCount; i++)
        's$i': (_) => support.feed(support.rss([
              for (var j = 0; j < 2; j++)
                support.rssItem(
                  constructiveTitles[(i * 2 + j) % constructiveTitles.length],
                  'https://s$i.example.com/story-$j',
                  DateTime.now().subtract(Duration(minutes: 10 + i * 20 + j * 5)),
                  desc: 'A short excerpt about story $j from source $i.',
                ),
            ])),
    };
  }

  List<Override> get overrides => [
        databaseProvider.overrideWithValue(db),
        storySourceProvider.overrideWithValue(
          DirectRssStorySource(FeedFetcher(client, retryBackoff: Duration.zero, sleep: (_) async {})),
        ),
        bundledSourcesProvider.overrideWith((ref) async => sources),
        linkOpenerProvider.overrideWithValue(links),
        sharerProvider.overrideWithValue(sharer),
        if (deadline != null)
          ingestionServiceProvider.overrideWith((ref) async {
            final classification = await ref.watch(classificationServiceProvider.future);
            return IngestionService(
              db: db,
              storySource: ref.watch(storySourceProvider),
              deadline: deadline!,
              classification: classification,
              afterRefresh: [classification.reclassifyOutdated, ref.watch(dedupeServiceProvider).refreshClusters],
            );
          }),
      ];

  Widget get app => ProviderScope(retry: (_, _) => null, overrides: overrides, child: const GoodNewsApp());

  Future<void> dispose() => db.close();
}

/// Lets real async work (SQLite, fake HTTP) progress while widget time is controlled.
Future<void> settle(WidgetTester tester, {int rounds = 12}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Pumps until [finder] matches (or fails after a while).
Future<void> pumpUntilFound(WidgetTester tester, Finder finder, {int rounds = 60}) async {
  for (var i = 0; i < rounds; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsWidgets, reason: 'timed out waiting for $finder');
}

/// All story cards currently built (by their `story-card-<id>` key).
final Finder storyCards = find.byWidgetPredicate((w) {
  final k = w.key;
  return k is ValueKey<String> && k.value.startsWith('story-card-');
});

/// Pre-fills the database like an earlier launch today: sources, [n] classified stories and
/// today's picks, so the cached-first path can be tested without any network.
Future<List<String>> seedCachedPicks(AppHarness h, {int n = 5}) async {
  await h.db.upsertBundledSources(h.sources);
  final ids = <String>[];
  for (var i = 0; i < n; i++) {
    ids.add(await support.addArticle(
      h.db,
      's${i % h.sourceCount}',
      slug: 'cached$i',
      title: constructiveTitles[i % constructiveTitles.length],
      score: 0.8 - i * 0.01,
      topics: ['topic$i'],
      publishedAt: DateTime.now().toUtc().subtract(Duration(minutes: 30 + i)),
      fetchedAt: DateTime.now().toUtc(),
    ));
  }
  await h.db.appendPicks(DailyPicksService.dayKey(DateTime.now()), ids);
  return ids;
}

/// Taps a bottom/rail navigation destination and lets the new screen load.
Future<void> goTo(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)).evaluate().isNotEmpty
      ? find.descendant(of: find.byType(NavigationBar), matching: find.text(label))
      : find.descendant(of: find.byType(NavigationRail), matching: find.text(label)));
  await settle(tester, rounds: 6);
}

/// Boots the app and waits until at least one story card is on screen.
Future<void> openApp(WidgetTester tester, AppHarness h) async {
  await tester.pumpWidget(h.app);
  await pumpUntilFound(tester, storyCards);
  await settle(tester, rounds: 6);
}

/// Taps the first story card (its tappable area, not the save button).
Future<void> tapFirstStory(WidgetTester tester) async {
  final target = find.descendant(of: storyCards.first, matching: find.byType(InkWell)).first;
  await tester.ensureVisible(target); // on small screens with large text it may start below the fold
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(target);
}

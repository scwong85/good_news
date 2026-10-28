import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/selection/daily_picks_service.dart';
import 'package:http/http.dart' as http;

import '../ingestion/test_support.dart' as support;
import '../support/app_harness.dart';

void main() {
  testWidgets('first open of the day: fetches, then shows and persists the day\'s picks', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    expect(storyCards, findsNWidgets(5));
    expect(find.textContaining('5 stories'), findsOneWidget);
    expect(find.textContaining('Updated'), findsOneWidget);
    expect(h.requests.where((r) => r.url.path.contains('feed')), isNotEmpty);
    final picks = await tester.runAsync(() => h.db.picksForDay(DailyPicksService.dayKey(DateTime.now())));
    expect(picks, hasLength(5));
  });

  testWidgets('shows a gathering state while the first picks are being created', (tester) async {
    final gate = Completer<void>();
    final h = AppHarness(routes: {
      for (var i = 0; i < 4; i++)
        's$i': (_) async {
          await gate.future;
          return support.feed(support.rss([support.rssItem(constructiveTitles[i], 'https://s$i.example.com/a', DateTime.now())]));
        },
    });
    addTearDown(h.dispose);
    await tester.pumpWidget(h.app);
    await pumpUntilFound(tester, find.text("Gathering today's stories…"));
    expect(storyCards, findsNothing);
    gate.complete();
    await pumpUntilFound(tester, storyCards);
  });

  testWidgets('cached picks appear immediately, even with no network', (tester) async {
    final h = AppHarness(online: false);
    addTearDown(h.dispose);
    await tester.runAsync(() => seedCachedPicks(h));
    final sw = Stopwatch()..start();
    await tester.pumpWidget(h.app);
    await pumpUntilFound(tester, storyCards);
    final firstContent = sw.elapsedMilliseconds;
    expect(storyCards, findsNWidgets(5));
    // Guard for the "cached launch to content < 1 s" goal (in-memory DB; device timing is unmeasured).
    expect(firstContent, lessThan(1000));
    await settle(tester);
    expect(find.text("You're offline. Showing your latest stories."), findsOneWidget);
    expect(storyCards, findsNWidgets(5)); // still there after the failed refresh
  });

  testWidgets('offline with nothing cached: empty state, then recovers via Try again', (tester) async {
    final h = AppHarness(online: false);
    addTearDown(h.dispose);
    await tester.pumpWidget(h.app);
    await pumpUntilFound(tester, find.text('No stories to show yet'));
    expect(find.textContaining('offline'), findsWidgets);
    expect(find.text("You're offline. Showing your latest stories."), findsNothing); // no contradictory banner
    h.online = true;
    await tester.tap(find.text('Try again'));
    await pumpUntilFound(tester, storyCards);
    expect(storyCards, findsNWidgets(5));
    expect(find.text('No stories to show yet'), findsNothing);
  });

  testWidgets('some sources failing: stories still show, with a quiet notice', (tester) async {
    final h = AppHarness();
    h.routes['s1'] = (_) async => http.Response('boom', 500);
    addTearDown(h.dispose);
    await openApp(tester, h);
    await settle(tester);
    expect(find.textContaining("1 of 4 sources couldn't be reached"), findsOneWidget);
    expect(storyCards, findsWidgets);
  });

  testWidgets('a hanging source cannot keep Today waiting past the deadline', (tester) async {
    final never = Completer<http.Response>();
    final h = AppHarness(deadline: const Duration(milliseconds: 400));
    h.routes['s2'] = (_) => never.future;
    addTearDown(h.dispose);
    await tester.pumpWidget(h.app);
    await pumpUntilFound(tester, storyCards);
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(storyCards, findsWidgets);
    expect(find.text("Gathering today's stories…"), findsNothing);
    // Let the abandoned request finish so no timer outlives the test.
    never.complete(http.Response('late', 200));
    await settle(tester);
  });

  testWidgets('pull to refresh and the refresh button fetch again, politely', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await settle(tester, rounds: 12);
    final base = h.requests.where((r) => r.url.path.contains('feed')).length;
    expect(base, 4);

    // The start-up refresh respected the cache; a first manual refresh bypasses it...
    await tester.tap(find.byTooltip('Refresh stories'));
    await settle(tester, rounds: 20);
    final afterFirst = h.requests.where((r) => r.url.path.contains('feed')).length;
    expect(afterFirst, 8);

    // ...but a second one within two minutes falls back to the 30 minute cache.
    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1500);
    await settle(tester, rounds: 20);
    expect(h.requests.where((r) => r.url.path.contains('feed')).length, afterFirst);
  });

  testWidgets('tapping a story opens it, and back returns to Today', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await tester.tap(find.byType(InkWell).first.hitTestable());
    await pumpUntilFound(tester, find.text('Why this story was included'));
    await tester.tap(find.byTooltip('Back'));
    await settle(tester, rounds: 6);
    expect(storyCards, findsWidgets);
    expect(find.text('Why this story was included'), findsNothing);
  });

  testWidgets('the day ends calmly, with a way into Explore', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await tester.ensureVisible(find.text('Browse more in Explore'));
    await tester.pump();
    expect(find.text("You're all caught up."), findsOneWidget);
    expect(find.textContaining('Come back tomorrow'), findsOneWidget);
    await tester.tap(find.text('Browse more in Explore'));
    await settle(tester, rounds: 6);
    expect(find.text('Search stories'), findsOneWidget);
  });

  testWidgets('raising stories per day in Settings adds stories to Today without reshuffling', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    String first() => tester.widget<Text>(find.descendant(of: storyCards.first, matching: find.byType(Text)).at(1)).data!;
    final before = first();
    await goTo(tester, 'Settings');
    await tester.drag(find.byType(Slider), const Offset(600, 0));
    await settle(tester, rounds: 10);
    await goTo(tester, 'Today');
    expect(find.textContaining('8 stories'), findsOneWidget); // only 8 distinct stories are available
    expect(first(), before);
  });
}

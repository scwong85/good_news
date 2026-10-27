import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/app/app.dart';
import 'package:good_news/app/router.dart';

import '../ingestion/test_support.dart' show loadRules;
import '../support/app_harness.dart';

Future<void> openFirstStory(WidgetTester tester) async {
  await tapFirstStory(tester);
  await pumpUntilFound(tester, find.text('Why this story was included'));
  await settle(tester, rounds: 4);
}

void main() {
  testWidgets('shows the story, its attribution, and why it was included', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await openFirstStory(tester);
    expect(find.text('Wetlands restored by volunteers, study finds 40% more birds'), findsOneWidget);
    expect(find.textContaining('Source s0'), findsWidgets);
    expect(find.text('A short excerpt about story 0 from source 0.'), findsOneWidget);
    expect(find.text('Read at Source s0'), findsOneWidget);
    expect(find.textContaining('Read the full story on their site'), findsOneWidget);
    expect(find.text('Highlighted today: it scored well against our criteria for constructive news.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
    expect(find.textContaining('No person has checked this story'), findsOneWidget);
    expect(find.textContaining('rules 2026'), findsOneWidget);
  });

  testWidgets('"Read at" opens the original page at the publisher', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await openFirstStory(tester);
    await tester.tap(find.text('Read at Source s0'));
    await settle(tester, rounds: 4);
    expect(h.links.opened.single.toString(), 'https://s0.example.com/story-0');
  });

  testWidgets('a link that cannot be opened is reported, not ignored', (tester) async {
    final h = AppHarness();
    h.links.result = false;
    addTearDown(h.dispose);
    await openApp(tester, h);
    await openFirstStory(tester);
    await tester.tap(find.text('Read at Source s0'));
    await settle(tester, rounds: 4);
    expect(find.text("Couldn't open the link."), findsOneWidget);
  });

  testWidgets('sharing sends the headline and the link to the original', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await openFirstStory(tester);
    await tester.tap(find.byTooltip('Share'));
    await settle(tester, rounds: 4);
    expect(h.sharer.shared.single.title, 'Wetlands restored by volunteers, study finds 40% more birds');
    expect(h.sharer.shared.single.url.toString(), 'https://s0.example.com/story-0');
  });

  testWidgets('saving stores only a small snapshot, and toggles back', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await openFirstStory(tester);
    await tester.tap(find.byTooltip('Save story'));
    await settle(tester, rounds: 6);
    expect(find.byTooltip('Remove from saved'), findsOneWidget);
    final rows = await tester.runAsync(() => h.db.allBookmarks());
    expect(rows, hasLength(1));
    final snapshot = rows!.single.snapshot;
    expect(snapshot, contains('"url":"https://s0.example.com/story-0"'));
    expect(snapshot.length, lessThan(3000)); // headline, short excerpt, links: never article text
    await tester.tap(find.byTooltip('Remove from saved'));
    await settle(tester, rounds: 6);
    expect(await tester.runAsync(() => h.db.allBookmarks()), isEmpty);
  });

  testWidgets('opening a story marks it as seen', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await openFirstStory(tester);
    await settle(tester, rounds: 4);
    expect(await tester.runAsync(() => h.db.seenIds()), hasLength(1));
  });

  testWidgets('an unknown story shows a friendly message', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    final container = ProviderScope.containerOf(tester.element(find.byType(GoodNewsApp)));
    container.read(routerProvider).push('/story/does-not-exist');
    await pumpUntilFound(tester, find.text('This story is no longer available'));
    await tester.tap(find.text('Go back'));
    await settle(tester, rounds: 4);
    expect(storyCards, findsWidgets);
  });

  testWidgets('the "worth knowing" notes appear when the rules noticed something', (tester) async {
    // A cached story whose stored explanation includes a caution rule.
    final h = AppHarness(online: false);
    addTearDown(h.dispose);
    final ids = await tester.runAsync(() => seedCachedPicks(h, n: 5));
    // Same rules version as the app, so the start-up re-classification leaves it alone.
    final version = loadRules().version;
    await tester.runAsync(() => h.db.customStatement(
          'UPDATE articles SET rules_version = ?, explanation = ? WHERE id = ?',
          [version, '{"reason":"","rules":[{"rule":"progress_terms","group":"positive","weight":0.1,"match":"restored"},{"rule":"opinion","group":"negative","weight":-0.3,"match":"essay"}]}', ids!.first],
        ));
    await openApp(tester, h);
    await openFirstStory(tester);
    expect(find.text('Worth knowing'), findsOneWidget);
    expect(find.text('May be an opinion piece'), findsOneWidget);
    expect(find.text('Reports progress or recovery'), findsOneWidget);
  });
}

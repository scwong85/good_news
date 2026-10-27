import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ingestion/test_support.dart' as support;
import '../support/app_harness.dart';

Future<void> typeSearch(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 400)); // debounce
  await settle(tester, rounds: 6);
}

void main() {
  testWidgets('lists every shown story from the last two weeks, newest first', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await goTo(tester, 'Explore');
    expect(storyCards, findsWidgets);
    expect(find.textContaining('8 stories from the last two weeks'), findsOneWidget);
    expect(find.text('Wetlands restored by volunteers, study finds 40% more birds'), findsOneWidget);
  });

  testWidgets('search narrows the list (title, excerpt and source name), and clearing restores it', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await goTo(tester, 'Explore');
    await typeSearch(tester, 'wetlands');
    expect(storyCards, findsOneWidget);
    expect(find.textContaining('1 story from'), findsOneWidget);
    await typeSearch(tester, 'source s2');
    expect(storyCards, findsWidgets);
    await tester.tap(find.byTooltip('Clear search'));
    await settle(tester, rounds: 6);
    expect(find.textContaining('8 stories from'), findsOneWidget);
  });

  testWidgets('every search word must match', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await goTo(tester, 'Explore');
    await typeSearch(tester, 'wetlands owls');
    expect(storyCards, findsNothing);
    expect(find.text('No stories match'), findsOneWidget);
  });

  testWidgets('topic chips filter, and filtering to nothing offers a way back', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await goTo(tester, 'Explore');
    await tester.tap(find.widgetWithText(FilterChip, 'Health'));
    await settle(tester, rounds: 6);
    expect(storyCards, findsWidgets);
    expect(find.text('Wetlands restored by volunteers, study finds 40% more birds'), findsNothing);
    expect(find.text('Clinic opens free care for families, study finds 30% fewer ER visits'), findsOneWidget);

    await typeSearch(tester, 'zzzz');
    expect(find.text('No stories match'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await settle(tester, rounds: 6);
    expect(find.textContaining('8 stories from'), findsOneWidget);
  });

  testWidgets('"More filters" offers story types; regions only appear when there is a choice', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await goTo(tester, 'Explore');
    await tester.tap(find.byTooltip('More filters'));
    await settle(tester, rounds: 6);
    expect(find.text('Type of story'), findsOneWidget);
    expect(find.text('Tags are assigned automatically and can be imperfect.'), findsOneWidget);
    expect(find.text('Region'), findsNothing); // every source is "global"
    await tester.tap(find.widgetWithText(FilterChip, 'Science & health'));
    await settle(tester, rounds: 6);
    expect(find.text('1'), findsWidgets); // the filter badge counts the chosen type
    await tester.tap(find.text('Clear all filters'));
    await settle(tester, rounds: 6);
  });

  testWidgets('the same story from two sources is listed once', (tester) async {
    final shared = constructiveTitles.first;
    final h = AppHarness(sourceCount: 2, routes: {
      for (var i = 0; i < 2; i++)
        's$i': (_) => support.feed(support.rss([
              support.rssItem(shared, 'https://s$i.example.com/shared', DateTime.now().subtract(Duration(minutes: 10 + i))),
            ])),
    });
    addTearDown(h.dispose);
    await openApp(tester, h);
    await goTo(tester, 'Explore');
    expect(storyCards, findsOneWidget);
  });

  testWidgets('sources switched off in Settings disappear from Explore', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await goTo(tester, 'Settings');
    await tester.ensureVisible(find.widgetWithText(SwitchListTile, 'Source s0'));
    await tester.pump(const Duration(milliseconds: 400)); // let the scroll finish before tapping
    await tester.tap(find.widgetWithText(SwitchListTile, 'Source s0'));
    await settle(tester, rounds: 8);
    final sources = await tester.runAsync(() => h.db.allSources());
    expect(sources!.firstWhere((s) => s.id == 's0').userEnabled, isFalse); // the tap really hit that switch
    await goTo(tester, 'Explore');
    expect(find.textContaining('Source s0'), findsNothing);
    expect(storyCards, findsWidgets);
  });

  testWidgets('opening a story from Explore works', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await goTo(tester, 'Explore');
    await tapFirstStory(tester);
    await pumpUntilFound(tester, find.text('Why this story was included'));
  });
}

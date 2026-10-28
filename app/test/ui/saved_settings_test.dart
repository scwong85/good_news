import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  group('Saved', () {
    testWidgets('starts empty, with guidance', (tester) async {
      final h = AppHarness();
      addTearDown(h.dispose);
      await openApp(tester, h);
      await goTo(tester, 'Saved');
      expect(find.text('Nothing saved yet'), findsOneWidget);
      expect(find.textContaining('available offline'), findsOneWidget);
    });

    testWidgets('a story saved from Today shows up in Saved, and can be removed with undo', (tester) async {
      final h = AppHarness();
      addTearDown(h.dispose);
      await openApp(tester, h);
      await tester.tap(find.byTooltip('Save story').first);
      await settle(tester, rounds: 6);
      await goTo(tester, 'Saved');
      expect(storyCards, findsOneWidget);
      await tester.tap(find.byTooltip('Remove from saved'));
      await settle(tester, rounds: 6);
      expect(find.text('Nothing saved yet'), findsOneWidget);
      expect(find.text('Removed from saved'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await settle(tester, rounds: 6);
      expect(storyCards, findsOneWidget);
    });

    testWidgets('saved stories survive the removal of their article and still open', (tester) async {
      final h = AppHarness(online: false);
      addTearDown(h.dispose);
      await tester.runAsync(() => seedCachedPicks(h));
      await openApp(tester, h);
      await tester.tap(find.byTooltip('Save story').first);
      await settle(tester, rounds: 6);
      // The old article is cleaned up by the app after a while; the saved copy must remain.
      await tester.runAsync(() => h.db.customStatement('DELETE FROM articles'));
      await goTo(tester, 'Saved');
      await pumpUntilFound(tester, storyCards);
      await tapFirstStory(tester);
      await pumpUntilFound(tester, find.text('Why this story was included'));
      expect(find.textContaining('Read at Source'), findsOneWidget);
    });

    testWidgets('saved stories are listed newest saved first', (tester) async {
      final h = AppHarness(online: false);
      addTearDown(h.dispose);
      await tester.runAsync(() => seedCachedPicks(h));
      await openApp(tester, h);
      final saves = find.byTooltip('Save story');
      await tester.tap(saves.at(0));
      await settle(tester, rounds: 4);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1100))); // saved_at has second resolution
      await tester.ensureVisible(find.byTooltip('Save story').first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byTooltip('Save story').first);
      await settle(tester, rounds: 4);
      await goTo(tester, 'Saved');
      expect(storyCards, findsNWidgets(2));
    });
  });

  group('Settings', () {
    testWidgets('topics you like are remembered', (tester) async {
      final h = AppHarness();
      addTearDown(h.dispose);
      await openApp(tester, h);
      await goTo(tester, 'Settings');
      await tester.tap(find.widgetWithText(FilterChip, 'Health'));
      await settle(tester, rounds: 6);
      expect(await tester.runAsync(() => h.db.getPreference('topics')), '["health"]');
      await tester.tap(find.widgetWithText(FilterChip, 'Health'));
      await settle(tester, rounds: 6);
      expect(await tester.runAsync(() => h.db.getPreference('topics')), '[]');
    });

    testWidgets('lists every source with a switch, and switching one off is remembered', (tester) async {
      final h = AppHarness();
      addTearDown(h.dispose);
      await openApp(tester, h);
      await goTo(tester, 'Settings');
      expect(find.byType(SwitchListTile, skipOffstage: false), findsNWidgets(4));
      await tester.ensureVisible(find.widgetWithText(SwitchListTile, 'Source s1'));
      await tester.pump(const Duration(milliseconds: 400)); // let the scroll finish before tapping
      await tester.tap(find.widgetWithText(SwitchListTile, 'Source s1'));
      await settle(tester, rounds: 8);
      final sources = await tester.runAsync(() => h.db.allSources());
      expect(sources!.firstWhere((s) => s.id == 's1').userEnabled, isFalse);
      expect(sources.where((s) => s.userEnabled), hasLength(3));
    });

    testWidgets('the stories-per-day slider spans 5 to 10', (tester) async {
      final h = AppHarness();
      addTearDown(h.dispose);
      await openApp(tester, h);
      await goTo(tester, 'Settings');
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect((slider.min, slider.max, slider.divisions), (5.0, 10.0, 5));
      expect(find.text('5 stories'), findsOneWidget);
      await tester.drag(find.byType(Slider), const Offset(-600, 0));
      await settle(tester, rounds: 6);
      expect(find.text('5 stories'), findsOneWidget); // cannot go below 5
    });

    testWidgets('the about page explains how stories are chosen, privacy and limits', (tester) async {
      final h = AppHarness();
      addTearDown(h.dispose);
      await openApp(tester, h);
      await goTo(tester, 'Settings');
      await tester.scrollUntilVisible(find.text('About and how stories are chosen'), 300, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text('About and how stories are chosen'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('About and how stories are chosen'));
      await pumpUntilFound(tester, find.text('How stories are chosen'));
      expect(find.text('What to keep in mind'), findsOneWidget);
      expect(find.textContaining('No person checks each'), findsOneWidget);
      expect(find.text('Your privacy'), findsOneWidget);
      expect(find.textContaining('No account, no ads and no tracking'), findsOneWidget);
      expect(find.text('Sources'), findsOneWidget);
      expect(find.textContaining('Selection rules version'), findsOneWidget);
    });
  });
}

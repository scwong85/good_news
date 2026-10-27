import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<AppHarness> boot(WidgetTester tester, {Brightness brightness = Brightness.light}) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final h = AppHarness(online: false);
  addTearDown(h.dispose);
  await tester.runAsync(() => seedCachedPicks(h));
  await openApp(tester, h);
  return h;
}

Future<void> expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    final mode = brightness.name;

    testWidgets('Today meets the tap-target, label and contrast guidelines ($mode)', (tester) async {
      final handle = tester.ensureSemantics();
      await boot(tester, brightness: brightness);
      await expectAccessible(tester);
      handle.dispose();
    });

    testWidgets('Story detail meets the guidelines ($mode)', (tester) async {
      final handle = tester.ensureSemantics();
      await boot(tester, brightness: brightness);
      await tapFirstStory(tester);
      await pumpUntilFound(tester, find.text('Why this story was included'));
      await settle(tester, rounds: 4);
      await expectAccessible(tester);
      handle.dispose();
    });

    testWidgets('Explore, Saved and Settings meet the guidelines ($mode)', (tester) async {
      final handle = tester.ensureSemantics();
      await boot(tester, brightness: brightness);
      await tester.tap(find.byTooltip('Save story').first);
      await settle(tester, rounds: 4);
      for (final tab in ['Explore', 'Saved', 'Settings']) {
        await goTo(tester, tab);
        await expectAccessible(tester);
      }
      handle.dispose();
    });
  }

  testWidgets('empty and offline states meet the guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    final h = AppHarness(online: false);
    addTearDown(h.dispose);
    await tester.pumpWidget(h.app);
    await pumpUntilFound(tester, find.text('No stories to show yet'));
    await expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('story cards are announced as buttons with headline, source and date', (tester) async {
    final handle = tester.ensureSemantics();
    await boot(tester);
    final label = tester.getSemantics(find.descendant(of: storyCards.first, matching: find.byType(InkWell)).first).label;
    expect(label, contains('Wetlands restored by volunteers'));
    expect(label, contains('Source s0'));
    expect(label, contains('Opens the story'));
    expect(find.byTooltip('Save story'), findsWidgets);
    handle.dispose();
  });

  testWidgets('the refresh action is available as a button, not only as a gesture', (tester) async {
    final handle = tester.ensureSemantics();
    await boot(tester);
    final node = tester.getSemantics(find.widgetWithIcon(IconButton, Icons.refresh));
    expect('${node.label} ${node.tooltip}', contains('Refresh stories'));
    expect(node.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('the stories-per-day slider reads as "N stories per day"', (tester) async {
    final handle = tester.ensureSemantics();
    await boot(tester);
    await goTo(tester, 'Settings');
    expect(find.semantics.byValue('5 stories per day'), findsOneWidget);
    handle.dispose();
  });
}

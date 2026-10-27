import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<AppHarness> bootAt(WidgetTester tester, Size size, {double textScale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearAllTestValues();
  });
  final h = AppHarness(online: false);
  addTearDown(h.dispose);
  await tester.runAsync(() => seedCachedPicks(h));
  await openApp(tester, h);
  return h;
}

void main() {
  const phone = Size(412, 892);
  const smallPhone = Size(320, 568);
  const tabletLandscape = Size(1000, 700);
  const tabletPortrait = Size(800, 1280);

  testWidgets('phones get a bottom navigation bar', (tester) async {
    await bootAt(tester, phone);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('tablets get a navigation rail, in both orientations', (tester) async {
    for (final size in [tabletLandscape, tabletPortrait]) {
      await bootAt(tester, size);
      expect(find.byType(NavigationRail), findsOneWidget, reason: '$size');
      expect(find.byType(NavigationBar), findsNothing, reason: '$size');
    }
  });

  testWidgets('on a wide screen the story column keeps a readable width and is centred', (tester) async {
    await bootAt(tester, tabletLandscape);
    final card = tester.getRect(storyCards.first);
    expect(card.width, lessThanOrEqualTo(720));
    final rail = tester.getRect(find.byType(NavigationRail));
    final free = Rect.fromLTRB(rail.right, 0, 1000, 700);
    expect((card.center.dx - free.center.dx).abs(), lessThan(24));
  });

  for (final (name, size, scale) in [
    ('phone at 100%', phone, 1.0),
    ('phone at 200% text', phone, 2.0),
    ('small phone at 130% text', smallPhone, 1.3),
    ('small phone at 200% text', smallPhone, 2.0),
    ('tablet at 200% text', tabletLandscape, 2.0),
  ]) {
    testWidgets('no overflow anywhere: $name', (tester) async {
      await bootAt(tester, size, textScale: scale);
      // Any RenderFlex overflow throws and fails the test.
      await tester.tap(find.byTooltip('Save story').first);
      await settle(tester, rounds: 3);
      for (final tab in ['Explore', 'Saved', 'Settings', 'Today']) {
        await goTo(tester, tab);
      }
      await goTo(tester, 'Today');
      await tapFirstStory(tester);
      await pumpUntilFound(tester, find.text('Why this story was included'));
      await tester.scrollUntilVisible(find.textContaining('No person has checked'), 200, scrollable: find.byType(Scrollable).first);
    });
  }
}

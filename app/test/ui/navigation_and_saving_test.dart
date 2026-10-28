import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

const _headline = 'Wetlands restored by volunteers, study finds 40% more birds';

void main() {
  testWidgets('saving a story keeps it in Today and in Explore (no reload flash)', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    final todayCount = storyCards.evaluate().length;

    await tester.tap(find.byTooltip('Save story').first);
    await tester.pump(); // the very next frame: nothing may disappear
    expect(find.text(_headline), findsOneWidget);
    await settle(tester, rounds: 6);
    expect(storyCards.evaluate().length, todayCount);
    expect(find.text(_headline), findsOneWidget);

    await goTo(tester, 'Explore');
    await pumpUntilFound(tester, storyCards);
    expect(find.text(_headline), findsOneWidget);
    await tester.tap(find.byTooltip('Remove from saved').first);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(_headline), findsOneWidget);
    await settle(tester, rounds: 6);
    expect(find.text(_headline), findsOneWidget);
  });

  testWidgets('the "Removed from saved" message goes away by itself', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await tester.tap(find.byTooltip('Save story').first);
    await settle(tester, rounds: 6);
    await goTo(tester, 'Saved');
    await tester.tap(find.byTooltip('Remove from saved').first);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Removed from saved'), findsOneWidget);
    // The timer starts once the slide-in finishes, so step past it in stages.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 3));
    }
    expect(find.text('Removed from saved'), findsNothing);
  });

  testWidgets('swiping left and right switches tabs', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    int tab() => tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;
    Future<void> swipe(double dx) async {
      await tester.flingFrom(const Offset(200, 400), Offset(dx, 0), 1500);
      await settle(tester, rounds: 6);
    }

    expect(tab(), 0);
    await swipe(-250);
    expect(tab(), 1);
    await swipe(-250);
    expect(tab(), 2);
    await swipe(250);
    expect(tab(), 1);
    await swipe(250);
    await swipe(250); // already on the first tab: stays
    expect(tab(), 0);
    for (var i = 0; i < 6; i++) {
      await swipe(-250); // and stops at the last tab
    }
    expect(tab(), 3);
  });

  testWidgets('swiping slides between tabs instead of jumping, and tapping a far tab does not bounce', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    int tab() => tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;
    expect(find.text('Search stories'), findsNothing); // other tabs are not on screen

    // Halfway through a drag both neighbouring tabs are on screen at once.
    final drag = await tester.startGesture(const Offset(300, 400));
    await drag.moveBy(const Offset(-40, 0));
    await tester.pump();
    await drag.moveBy(const Offset(-150, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Search stories'), findsOneWidget); // Explore is sliding in beside Today
    expect(storyCards, findsWidgets); // while Today is still partly visible
    expect(tab(), 0); // not switched until the drag settles
    await drag.up();
    await settle(tester, rounds: 8);
    expect(tab(), anyOf(0, 1));

    // Tapping a tab three places away lands there and stays there.
    await goTo(tester, 'Settings');
    await settle(tester, rounds: 6);
    expect(tab(), 3);
  });
}

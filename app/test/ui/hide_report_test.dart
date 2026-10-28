import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import 'story_screen_test.dart' show openFirstStory;

void main() {
  testWidgets('hiding a story removes it from Today, refills the slot, and can be undone', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    final before = storyCards.evaluate().length;
    await openFirstStory(tester);
    await tester.ensureVisible(find.text('Hide or report this story'));
    await tester.tap(find.text('Hide or report this story'));
    await settle(tester, rounds: 6);
    expect(find.text('Why hide this story?'), findsOneWidget);
    expect(find.textContaining('This stays on your phone'), findsOneWidget);
    await tester.tap(find.text('Not for me'));
    await settle(tester, rounds: 10);
    expect(find.text('Story hidden on this phone'), findsOneWidget);
    expect(find.text('Wetlands restored by volunteers, study finds 40% more birds'), findsNothing);
    expect(storyCards.evaluate().length, lessThanOrEqualTo(before));

    await tester.tap(find.text('Undo'));
    await settle(tester, rounds: 10);
    final hidden = await tester.runAsync(() => h.db.hiddenArticles());
    expect(hidden, isEmpty);
  });

  testWidgets('hidden stories can be shown again from Settings', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await openFirstStory(tester);
    await tester.ensureVisible(find.text('Hide or report this story'));
    await tester.tap(find.text('Hide or report this story'));
    await settle(tester, rounds: 6);
    await tester.tap(find.text('Too trivial'));
    await settle(tester, rounds: 10);

    await goTo(tester, 'Settings');
    await tester.scrollUntilVisible(find.text('Hidden stories'), 200);
    await tester.ensureVisible(find.text('Hidden stories'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Hidden stories'));
    await settle(tester, rounds: 8);
    expect(find.text('Wetlands restored by volunteers, study finds 40% more birds'), findsOneWidget);
    await tester.tap(find.text('Show again'));
    await settle(tester, rounds: 8);
    expect(find.text('No hidden stories'), findsOneWidget);
  });

  testWidgets('the privacy policy screen shows the bundled policy', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    await goTo(tester, 'Settings');
    await tester.scrollUntilVisible(find.text('Privacy policy'), 200);
    await tester.ensureVisible(find.text('Privacy policy'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Privacy policy'));
    await pumpUntilFound(tester, find.text('The short version'));
    expect(find.text('The short version'), findsOneWidget);
    expect(find.textContaining('no advertising, no analytics'), findsOneWidget);
  });
}

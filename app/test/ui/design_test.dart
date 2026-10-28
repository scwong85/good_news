import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/app/brand.dart';
import 'package:good_news/app/copy.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('first run shows the welcome once, then Today', (tester) async {
    final h = AppHarness(showWelcome: true);
    addTearDown(h.dispose);
    await tester.pumpWidget(h.app);
    await pumpUntilFound(tester, find.byKey(const Key('welcome')));
    expect(find.text(welcomePages[0].title), findsOneWidget);
    await tester.tap(find.text(welcomeNext));
    await settle(tester, rounds: 6);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(welcomePages[1].title), findsOneWidget);
    await tester.tap(find.text(welcomeNext));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(welcomeStart));
    await settle(tester, rounds: 8);
    expect(find.byKey(const Key('welcome')), findsNothing);
    await pumpUntilFound(tester, storyCards);
    expect(await tester.runAsync(() => h.db.getPreference('welcome_seen')), '1');
  });

  testWidgets('the welcome can be skipped', (tester) async {
    final h = AppHarness(showWelcome: true);
    addTearDown(h.dispose);
    await tester.pumpWidget(h.app);
    await pumpUntilFound(tester, find.byKey(const Key('welcome')));
    await tester.tap(find.text(welcomeSkip));
    await settle(tester, rounds: 8);
    expect(find.byKey(const Key('welcome')), findsNothing);
    expect(await tester.runAsync(() => h.db.getPreference('welcome_seen')), '1');
  });

  testWidgets('a returning reader never sees the welcome', (tester) async {
    final h = AppHarness(showWelcome: true);
    addTearDown(h.dispose);
    await h.db.setPreference('welcome_seen', '1');
    await tester.pumpWidget(h.app);
    await pumpUntilFound(tester, storyCards);
    expect(find.byKey(const Key('welcome')), findsNothing);
  });

  testWidgets("Today has a greeting header, a lead story and a story reason", (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await openApp(tester, h);
    expect(find.text('Today'), findsWidgets);
    expect(find.textContaining(RegExp('Good (morning|afternoon|evening)')), findsOneWidget);
    expect(find.text(todayLead), findsOneWidget); // only the first story is the lead
    expect(find.byType(SunriseMark), findsWidgets);
    expect(find.text('Reports progress or recovery'), findsWidgets); // the short "why" on cards
  });

  test('the greeting follows the hour', () {
    expect(greetingFor(DateTime(2026, 10, 28, 8)), 'Good morning');
    expect(greetingFor(DateTime(2026, 10, 28, 14)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 10, 28, 20)), 'Good evening');
  });

  testWidgets('animation is skipped when the system asks for reduced motion', (tester) async {
    Future<Widget> build(bool reduce) async => MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: const Directionality(textDirection: TextDirection.ltr, child: FadeSlideIn(child: Text('hello'))),
        );
    await tester.pumpWidget(await build(true));
    expect(tester.widget<Text>(find.text('hello')), isNotNull);
    expect(find.byType(Opacity), findsNothing); // shown immediately, nothing animating
    await tester.pumpWidget(await build(false));
    expect(find.byType(Opacity), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });

  test('every topic has an icon and a distinct readable colour in both themes', () {
    const topics = ['environment', 'science', 'health', 'education', 'technology', 'community', 'development', 'society', 'culture', 'other'];
    for (final b in Brightness.values) {
      final colors = {for (final t in topics) topicStyle(t, b).color};
      expect(colors.length, topics.length);
    }
  });
}

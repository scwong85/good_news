import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

void main() {
  testWidgets('the app boots, fetches, and shows today\'s stories', (tester) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await tester.pumpWidget(h.app);
    await pumpUntilFound(tester, find.textContaining('Wetlands restored'));
    await settle(tester);
    expect(find.text('Today'), findsWidgets);
    // ignore: avoid_print
    print('cards: ${storyCards.evaluate().length}; titles: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().where((s) => s.length > 30).take(12).toList()}');
    expect(storyCards, findsWidgets);
    // the day's picks were persisted
    final picks = await tester.runAsync(() => h.db.picksForDay(DateTime.now().toLocal().toString().substring(0, 10)));
    // ignore: avoid_print
    print('persisted picks: ${picks?.length}');
  });
}

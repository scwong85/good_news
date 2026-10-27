import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// The main reader journey, end to end, on in-memory storage and a fake web. Used by the normal
/// widget test (`test/app_flow_test.dart`) and by the device test (`integration_test/app_test.dart`).
Future<void> runAppFlow(WidgetTester tester) async {
  final h = AppHarness();
  addTearDown(h.dispose);

  // 1. Open the app: feeds are fetched, today's picks appear.
  await openApp(tester, h);
  expect(storyCards, findsNWidgets(5));
  expect(find.textContaining('5 stories'), findsOneWidget);

  // 2. Read a story: why it was included, then to the original publisher.
  await tapFirstStory(tester);
  await pumpUntilFound(tester, find.text('Why this story was included'));
  await tester.tap(find.text('Read at Source s0'));
  await settle(tester, rounds: 4);
  expect(h.links.opened.single.host, 's0.example.com');

  // 3. Save it and go back.
  await tester.tap(find.byTooltip('Save story'));
  await settle(tester, rounds: 4);
  await tester.tap(find.byTooltip('Back'));
  await settle(tester, rounds: 6);

  // 4. Explore: search narrows the list.
  await goTo(tester, 'Explore');
  await tester.enterText(find.byType(TextField), 'wetlands');
  await tester.pump(const Duration(milliseconds: 400));
  await settle(tester, rounds: 6);
  expect(storyCards, findsOneWidget);

  // 5. Saved shows the story.
  await goTo(tester, 'Saved');
  expect(storyCards, findsOneWidget);

  // 6. Settings: more stories per day; Today grows without reshuffling.
  await goTo(tester, 'Settings');
  await tester.drag(find.byType(Slider), const Offset(600, 0));
  await settle(tester, rounds: 10);
  await goTo(tester, 'Today');
  expect(find.textContaining('8 stories'), findsOneWidget);

  // 7. Losing the network keeps the stories and says so.
  h.online = false;
  await tester.tap(find.byTooltip('Refresh stories'));
  await pumpUntilFound(tester, find.text("You're offline. Showing your latest stories."));
  expect(storyCards, findsWidgets);
}

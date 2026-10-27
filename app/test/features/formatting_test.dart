import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/features/shared/formatting.dart';

void main() {
  // Local times throughout: the formatters work in the reader's local calendar.
  final now = DateTime(2026, 10, 27, 15, 30);

  group('formatStoryDate', () {
    test('same day shows the time', () => expect(formatStoryDate(DateTime(2026, 10, 27, 9, 5), now), 'Today, 09:05'));
    test('yesterday', () => expect(formatStoryDate(DateTime(2026, 10, 26, 23, 59), now), 'Yesterday'));
    test('within a week shows the weekday', () {
      expect(formatStoryDate(DateTime(2026, 10, 24, 12), now), 'Sat');
      expect(formatStoryDate(DateTime(2026, 10, 21, 12), now), 'Wed');
    });
    test('older shows day and month, plus the year when different', () {
      expect(formatStoryDate(DateTime(2026, 10, 12, 12), now), '12 Oct');
      expect(formatStoryDate(DateTime(2025, 12, 31, 12), now), '31 Dec 2025');
    });
    test('late-night stories belong to their local day', () {
      final lateYesterday = DateTime(2026, 10, 26, 23, 59);
      final earlyToday = DateTime(2026, 10, 27, 0, 1);
      expect(formatStoryDate(lateYesterday, DateTime(2026, 10, 27, 0, 30)), 'Yesterday');
      expect(formatStoryDate(earlyToday, DateTime(2026, 10, 27, 0, 30)), 'Today, 00:01');
    });
  });

  group('formatUpdated', () {
    test('just now', () => expect(formatUpdated(now.subtract(const Duration(seconds: 20)), now), 'just now'));
    test('minutes', () => expect(formatUpdated(now.subtract(const Duration(minutes: 12)), now), '12 min ago'));
    test('hours', () => expect(formatUpdated(now.subtract(const Duration(hours: 3, minutes: 5)), now), '3 h ago'));
    test('a day or more', () {
      expect(formatUpdated(now.subtract(const Duration(hours: 30)), now), 'yesterday');
      expect(formatUpdated(now.subtract(const Duration(days: 4)), now), '4 days ago');
    });
  });

  test('formatLongDay', () {
    expect(formatLongDay(DateTime(2026, 10, 27)), 'Tuesday 27 October');
    expect(formatLongDay(DateTime(2026, 1, 1)), 'Thursday 1 January');
  });

  test('labels', () {
    expect(topicLabel('environment'), 'Environment');
    expect(topicLabel(''), '');
    expect(storyTypeLabel('science_health'), 'Science & health');
    expect(storyTypeLabel('education_opportunity'), 'Education & opportunity');
    expect(storyTypeLabel('progress'), 'Progress');
  });
}

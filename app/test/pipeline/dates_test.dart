import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/pipeline/dates.dart';

void main() {
  DateTime utc(int y, int mo, int d, [int h = 0, int mi = 0, int s = 0]) =>
      DateTime.utc(y, mo, d, h, mi, s);

  test('RFC 822 with weekday and numeric zone', () {
    expect(parseFeedDate('Tue, 27 Oct 2026 07:00:17 +0000'), utc(2026, 10, 27, 7, 0, 17));
  });
  test('RFC 822 without weekday (Mongabay style)', () {
    expect(parseFeedDate('27 Oct 2026 18:59:25 +0000'), utc(2026, 10, 27, 18, 59, 25));
  });
  test('named and offset zones convert to UTC', () {
    expect(parseFeedDate('Tue, 27 Oct 2026 17:13:00 GMT'), utc(2026, 10, 27, 17, 13));
    expect(parseFeedDate('Tue, 27 Oct 2026 10:00:00 EST'), utc(2026, 10, 27, 15));
    expect(parseFeedDate('Tue, 27 Oct 2026 10:00:00 +0200'), utc(2026, 10, 27, 8));
    expect(parseFeedDate('Tue, 27 Oct 2026 10:00:00 -0530'), utc(2026, 10, 27, 15, 30));
  });
  test('missing seconds and 2-digit year', () {
    expect(parseFeedDate('Tue, 27 Oct 26 07:05 GMT'), utc(2026, 10, 27, 7, 5));
  });
  test('ISO 8601 with Z, offset, and no zone (treated as UTC)', () {
    expect(parseFeedDate('2026-10-27T17:13:00Z'), utc(2026, 10, 27, 17, 13));
    expect(parseFeedDate('2026-10-26T12:30:00+02:00'), utc(2026, 10, 26, 10, 30));
    final noZone = parseFeedDate('2026-10-26 12:30:00')!;
    expect(noZone.isUtc, isTrue);
    expect(noZone, utc(2026, 10, 26, 12, 30));
  });
  test('garbage returns null', () {
    for (final bad in [null, '', '   ', 'yesterday', '32 Foo 2026 10:00 GMT', 'Tue, 27 Oct 2026 25:00:00 GMT']) {
      expect(parseFeedDate(bad), isNull, reason: '$bad');
    }
  });
}

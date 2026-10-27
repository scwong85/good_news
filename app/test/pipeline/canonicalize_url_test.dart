import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/pipeline/canonicalize_url.dart';

void main() {
  final golden = (jsonDecode(File('test/fixtures/golden_urls.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  group('parity with the Python reference (golden_urls.json)', () {
    for (final c in golden) {
      final input = c['input'] as String;
      final expected = c['expected'] as String?;
      test('canonicalize ${jsonEncode(input)}', () {
        if (expected == null) {
          expect(() => canonicalizeUrl(input), throwsA(isA<InvalidUrl>()));
        } else {
          expect(canonicalizeUrl(input), expected);
        }
      });
    }
  });

  test('is idempotent', () {
    for (final c in golden.where((c) => c['expected'] != null)) {
      final once = canonicalizeUrl(c['input'] as String);
      expect(canonicalizeUrl(once), once);
    }
  });
}

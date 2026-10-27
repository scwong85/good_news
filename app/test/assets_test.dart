import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/core/providers.dart';

void main() {
  test('bundled sources load and look sane', () async {
    final sources = await loadBundledSources((p) async => File(p).readAsStringSync());
    expect(sources.length, greaterThanOrEqualTo(10));
    expect(sources.map((s) => s.id).toSet().length, sources.length);
    for (final s in sources) {
      expect(Uri.parse(s.rssUrl).scheme, 'https', reason: s.id);
      expect(s.trustScore, inInclusiveRange(0, 1));
      expect(s.tier, inInclusiveRange(1, 3));
    }
  });

  test('rules asset is present and matches the repository copy', () {
    final bundled = File('assets/rules/rules.json').readAsStringSync();
    final canonical = File('../rules/rules.json').readAsStringSync();
    expect(bundled, canonical, reason: 'run scripts/sync-rules.sh');
    expect(jsonDecode(bundled)['rules_version'], isNotEmpty);
  });
}

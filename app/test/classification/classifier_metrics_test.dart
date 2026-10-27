import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/pipeline/classifier.dart';
import 'package:good_news/pipeline/rules.dart';

/// Re-derives the Phase 2 metrics with the Dart classifier on the labeled data, and checks them
/// against rules/baseline_metrics.json (written by the Python evaluator).
void main() {
  final rules = Rules.parse(File('assets/rules/rules.json').readAsStringSync());
  final trust = {
    for (final s in (jsonDecode(File('assets/sources.json').readAsStringSync())['sources'] as List))
      s['name'] as String: (s['trust_score'] as num).toDouble(),
  };
  final tier1 = {
    for (final s in (jsonDecode(File('assets/sources.json').readAsStringSync())['sources'] as List))
      if (s['tier'] == 1) s['name'] as String,
  };
  final labels = File('../data/seed_labels.jsonl')
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .map((l) => jsonDecode(l) as Map<String, dynamic>)
      .toList();
  final baseline = jsonDecode(File('../rules/baseline_metrics.json').readAsStringSync()) as Map<String, dynamic>;

  Map<String, double> metrics(Set<String> splits) {
    final rows = labels.where((r) => splits.contains(r['split'])).toList();
    var todayPred = 0, todayTp = 0, shownPred = 0, shownTp = 0, ok = 0, tier1Ok = 0, tier1N = 0;
    for (final r in rows) {
      final out = classify(
        ClassifierItem(
          source: r['source'] as String,
          title: r['title'] as String,
          excerpt: (r['excerpt'] as String?) ?? '',
          url: r['url'] as String,
          publishedAt: DateTime.parse(r['published_at'] as String),
          sourceTrust: trust[r['source']] ?? 0.5,
        ),
        rules,
      );
      final gold = r['label'] == 'constructive';
      final shown = out.route != routeExcluded;
      if (out.route == routeToday) {
        todayPred++;
        if (gold) todayTp++;
      }
      if (shown) {
        shownPred++;
        if (gold) shownTp++;
      }
      if (shown == gold) ok++;
      if (tier1.contains(r['source'])) {
        tier1N++;
        if (shown == gold) tier1Ok++;
      }
    }
    double r3(double x) => (x * 1000).round() / 1000;
    return {
      'n': rows.length.toDouble(),
      'route_accuracy': r3(ok / rows.length),
      'tier1_route_accuracy': r3(tier1Ok / tier1N),
      'today_precision': r3(todayPred == 0 ? 0 : todayTp / todayPred),
      'shown_precision': r3(shownPred == 0 ? 0 : shownTp / shownPred),
    };
  }

  test('rules version matches the baseline file', () => expect(rules.version, baseline['rules_version']));

  for (final entry in {'dev': {'dev'}, 'dev2': {'dev2'}, 'tune': {'dev', 'dev2'}, 'test2': {'test2'}}.entries) {
    test('Dart metrics equal the Python baseline on ${entry.key}', () {
      final dart = metrics(entry.value);
      final py = baseline[entry.key] as Map<String, dynamic>;
      expect(dart['n'], (py['n'] as num).toDouble());
      for (final k in ['route_accuracy', 'tier1_route_accuracy', 'today_precision', 'shown_precision']) {
        expect(dart[k], closeTo((py[k] as num).toDouble(), 0.0015), reason: '${entry.key} $k');
      }
    });
  }

  test('Phase 2 acceptance holds on the blind held-out set (test2)', () {
    final m = metrics({'test2'});
    expect(m['today_precision'], greaterThanOrEqualTo(0.85));
    expect(m['shown_precision'], greaterThanOrEqualTo(0.75));
  });
}

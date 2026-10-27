import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/pipeline/classifier.dart';
import 'package:good_news/pipeline/rules.dart';

/// Parity with the Python reference: every case in rules/golden_cases.jsonl
/// (all 290 labeled articles plus synthetic Stage-1 cases).
void main() {
  final rules = Rules.parse(File('assets/rules/rules.json').readAsStringSync());
  final cases = File('../rules/golden_cases.jsonl')
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .map((l) => jsonDecode(l) as Map<String, dynamic>)
      .toList();

  ClassifierItem itemOf(Map<String, dynamic> input) => ClassifierItem(
        source: input['source'] as String,
        title: input['title'] as String,
        excerpt: input['excerpt'] as String,
        url: input['url'] as String,
        publishedAt: input['published_at'] == null ? null : DateTime.parse(input['published_at'] as String),
        sourceTrust: (input['source_trust'] as num).toDouble(),
        language: input['language'] as String?,
      );

  test('golden file is present and large enough', () => expect(cases.length, greaterThanOrEqualTo(290)));

  List<String> compare(Rules rules) {
    final mismatches = <String>[];
    for (final c in cases) {
      final expected = c['expected'] as Map<String, dynamic>;
      final now = c['now'] == null ? null : DateTime.parse(c['now'] as String);
      final out = classify(itemOf(c['input'] as Map<String, dynamic>), rules, now: now);
      final problems = <String>[];
      if (out.route != expected['route']) problems.add('route ${out.route} != ${expected['route']}');
      if (out.reason != expected['reason']) problems.add('reason ${out.reason} != ${expected['reason']}');
      if ((out.score - (expected['score'] as num)).abs() > 1e-6) {
        problems.add('score ${out.score} != ${expected['score']}');
      }
      if (out.topics.join(',') != (expected['topics'] as List).join(',')) problems.add('topics');
      if (out.storyTypes.join(',') != (expected['story_types'] as List).join(',')) problems.add('story_types');
      if (out.evidenceSignals.join(',') != (expected['evidence_signals'] as List).join(',')) {
        problems.add('signals');
      }
      if (out.explanation.map((e) => e.rule).join(',') != (expected['rules'] as List).join(',')) {
        problems.add('rules ${out.explanation.map((e) => e.rule).join(',')} != ${(expected['rules'] as List).join(',')}');
      }
      if (problems.isNotEmpty) mismatches.add('${c['name']}: ${problems.join('; ')}');
    }
    return mismatches;
  }

  test('every golden case matches the Python reference', () {
    final mismatches = compare(rules);
    expect(mismatches, isEmpty, reason: '${mismatches.length} of ${cases.length} differ:\n${mismatches.take(15).join('\n')}');
  });

  test('the comparison is sensitive: slightly different rules are detected', () {
    final json = jsonDecode(File('assets/rules/rules.json').readAsStringSync()) as Map<String, dynamic>;
    json['base_score'] = (json['base_score'] as num) + 0.01;
    expect(compare(Rules.fromJson(json)), isNotEmpty);
  });
}

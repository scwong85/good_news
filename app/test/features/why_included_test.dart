import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/features/shared/story.dart';
import 'package:good_news/features/story/why_included.dart';

Story story({String? route = 'today', double? score = 0.67, String? version = '2026.11.2', String? explanation}) => Story(
      id: 'a1',
      title: 'Title',
      excerpt: 'Excerpt',
      url: 'https://example.com/a',
      sourceId: 's',
      sourceName: 'Source',
      publishedAt: DateTime.utc(2026, 10, 27),
      route: route,
      score: score,
      rulesVersion: version,
      explanationJson: explanation,
    );

String rules(List<(String, double)> list) => jsonEncode({
      'reason': '',
      'rules': [for (final (id, w) in list) {'rule': id, 'group': w > 0 ? 'positive' : 'negative', 'weight': w, 'match': 'x'}],
    });

void main() {
  test('headline depends on the route', () {
    expect(whyIncluded(story(route: 'today')).headline, startsWith('Highlighted today'));
    expect(whyIncluded(story(route: 'explore')).headline, contains('partly matches'));
    expect(whyIncluded(story(route: null)).headline, 'Saved from an earlier day.');
  });

  test('reasons are the strongest positive findings, at most four, without repeats', () {
    final why = whyIncluded(story(explanation: rules([
      ('sig_data', 0.10), ('progress_terms', 0.10), ('collab_terms', 0.08), ('sig_study', 0.08),
      ('solution_terms', 0.06), ('action_terms', 0.06), ('source_prior', 0.05), //
    ])));
    expect(why.reasons, hasLength(4));
    expect(why.reasons.toSet(), hasLength(4));
    expect(why.reasons.first, anyOf('Cites figures or data', 'Reports progress or recovery'));
    expect(why.reasons, isNot(contains('source_prior')));
  });

  test('cautions come from negative findings, at most two', () {
    final why = whyIncluded(story(explanation: rules([
      ('progress_terms', 0.1), ('opinion', -0.3), ('harm_terms', -0.12), ('clickbait', -0.14), //
    ])));
    expect(why.cautions, ['May be an opinion piece', 'Mentions difficult events or problems']);
  });

  test('unknown rule ids are ignored rather than shown raw', () {
    final why = whyIncluded(story(explanation: rules([('brand_new_rule', 0.5), ('sig_data', 0.1)])));
    expect(why.reasons, ['Cites figures or data']);
  });

  test('missing, empty or malformed explanations still give a useful answer', () {
    for (final raw in [null, '', 'not json', '{"rules": "oops"}', '[]']) {
      final why = whyIncluded(story(explanation: raw));
      expect(why.headline, isNotEmpty);
      expect(why.reasons, isEmpty);
      expect(why.footnote, contains('not independently verified'));
    }
  });

  test('always carries the honesty footnote and, when known, score and rules version', () {
    final why = whyIncluded(story());
    expect(why.footnote, contains('No person has checked this story'));
    expect(why.detail, 'Score 0.67 · rules 2026.11.2');
    expect(whyIncluded(story(score: null)).detail, isNull);
    expect(whyIncluded(story(version: null)).detail, 'Score 0.67');
  });
}

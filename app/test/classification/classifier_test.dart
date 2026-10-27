import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/pipeline/classifier.dart';
import 'package:good_news/pipeline/rules.dart';

final now = DateTime.utc(2026, 10, 27, 12);
late Rules rules;

ClassifierItem item(
  String title, {
  String excerpt = '',
  String url = 'https://example.com/a',
  DateTime? publishedAt,
  double trust = 0.95,
  String source = 'Positive News',
  String? language,
}) =>
    ClassifierItem(
      source: source,
      title: title,
      excerpt: excerpt,
      url: url,
      publishedAt: publishedAt ?? now.subtract(const Duration(days: 1)),
      sourceTrust: trust,
      language: language,
    );

void main() {
  setUpAll(() => rules = Rules.parse(File('assets/rules/rules.json').readAsStringSync()));

  group('stage 1', () {
    final cases = <String, ClassifierItem>{
      'invalid_url': item('Wetlands restored by volunteers', url: 'ftp://example.com/a'),
      'missing_title': item('   '),
      'missing_date': ClassifierItem(
        source: 's', title: 'Wetlands restored', excerpt: '', url: 'https://e.com/a', publishedAt: null),
      'too_old': item('Wetlands restored by volunteers', publishedAt: now.subtract(const Duration(days: 30))),
      'stage1:sponsored_url': item('Wetlands restored by volunteers', url: 'https://e.com/sponsored/x'),
      'unsupported_language': item('Wetlands restored by volunteers', language: 'fr'),
      'stage1:roundup_good_news': item('Good News This Week: October 24'),
      'stage1:reading_list': item('What We’re Reading: trees'),
    };
    cases.forEach((reason, it) {
      test('excluded: $reason', () {
        final out = classify(it, rules, now: now);
        expect((out.route, out.reason, out.score), (routeExcluded, reason, 0));
        expect(out.rulesVersion, rules.version);
      });
    });

    test('the age filter only applies when a current time is given', () {
      final old = item('Wetlands restored by volunteers', publishedAt: now.subtract(const Duration(days: 400)));
      expect(classify(old, rules).route, isNot(routeExcluded));
      expect(classify(old, rules, now: now).reason, 'too_old');
    });

    test('source-specific excludes apply only to that source', () {
      final yes = item('Inspiration: Someone', source: 'YES! Magazine', trust: 0.6);
      final other = item('Inspiration: Someone');
      expect(classify(yes, rules, now: now).reason, 'stage1:yes_inspiration_column');
      expect(classify(other, rules, now: now).reason, isNot('stage1:yes_inspiration_column'));
    });
  });

  group('scoring and routing', () {
    test('a strong constructive story is routed to today', () {
      final out = classify(item('Wetlands restored by volunteers, study finds 40% more birds'), rules, now: now);
      expect(out.route, routeToday);
      expect(out.score, greaterThanOrEqualTo(rules.todayThreshold));
      expect(out.evidenceSignals, containsAll(['data_cited', 'study_referenced']));
      expect(out.topics, contains('environment'));
    });

    test('negative news is excluded', () {
      final out = classify(item('Attack kills dozens as war crisis deepens', trust: 0.5), rules, now: now);
      expect((out.route, out.reason), (routeExcluded, 'low_score'));
    });

    test('listicles and how-tos score lower', () {
      double score(String t) => classify(item(t), rules, now: now).score;
      final base = score('Wetlands restored by volunteers');
      expect(score('5 ways wetlands restored by volunteers'), lessThan(base));
      expect(score('How to help wetlands restored by volunteers'), lessThan(base));
    });

    test('today needs evidence unless the source is highly trusted', () {
      const text = 'Volunteers launched a partnership to restore and protect a river';
      final trusted = classify(item(text, trust: 0.95), rules, now: now);
      final untrusted = classify(item(text, trust: 0.7), rules, now: now);
      expect(trusted.route, routeToday);
      expect(trusted.evidenceSignals, isEmpty);
      expect((untrusted.route, untrusted.reason), (routeExplore, 'no_evidence'));
    });

    test('today needs constructive vocabulary, not evidence alone', () {
      final out = classify(item('New study of 12,000 people at the University of Oxford', trust: 0.7), rules, now: now);
      expect(out.route, isNot(routeToday));
    });

    test('a veto keeps a story out of today', () {
      final out = classify(
        item('Volunteers restored a river despite the war, study finds 40% recovery'), rules, now: now);
      expect(out.route, isNot(routeToday));
    });

    test('score is clamped to [0, 1] and rounded to 6 places', () {
      final low = classify(item('war attack killed genocide scandal fraud lawsuit', trust: 0.1), rules, now: now);
      expect(low.score, inInclusiveRange(0, 1));
      expect(low.score, double.parse(low.score.toStringAsFixed(6)));
    });

    test('every decision carries an explanation', () {
      final out = classify(item('Wetlands restored by volunteers'), rules, now: now);
      expect(out.explanation, isNotEmpty);
      expect(out.explanationJson()['rules'], isA<List>());
      expect(jsonEncode(out.explanationJson()), contains('progress_terms'));
      expect(classify(item('   '), rules, now: now).reason, isNotEmpty);
    });

    test('classification is deterministic', () {
      String run() => jsonEncode(
          classify(item('Wetlands restored by volunteers, study finds 40% more birds'), rules, now: now).explanationJson());
      expect(run(), run());
    });

    test('non-ASCII letters are not word characters (shared ASCII regex semantics)', () {
      // Like the Python reference: "é" does not extend a word, so \\bwar matches in "éwar".
      final out = classify(item('éwar and wetlands restored by volunteers'), rules, now: now);
      expect(out.explanation.map((e) => e.rule), contains('harm_terms'));
    });

    test('whitespace runs are collapsed before matching', () {
      final a = classify(item('Volunteers  restored 40 percent of wetlands'), rules, now: now);
      final b = classify(item('Volunteers restored 40 percent of wetlands'), rules, now: now);
      expect(a.score, b.score);
    });
  });

  group('rules loading', () {
    Map<String, dynamic> raw() => jsonDecode(File('assets/rules/rules.json').readAsStringSync()) as Map<String, dynamic>;

    test('the bundled rules parse', () {
      expect(rules.version, isNotEmpty);
      expect(rules.exploreThreshold, lessThan(rules.todayThreshold));
      expect(rules.scoreRules.map((r) => r.id).toSet().length, rules.scoreRules.length);
    });

    test('missing keys, duplicate ids, unknown groups and bad regexes are rejected', () {
      void expectRejected(void Function(Map<String, dynamic>) mutate) {
        final json = raw();
        mutate(json);
        expect(() => Rules.fromJson(json), throwsA(isA<RulesException>()));
      }

      expectRejected((j) => j.remove('thresholds'));
      expectRejected((j) => (j['score_rules'] as List)[1]['id'] = (j['score_rules'] as List)[0]['id']);
      expectRejected((j) => (j['score_rules'] as List)[0]['group'] = 'nope');
      expectRejected((j) => (j['score_rules'] as List)[0]['field'] = 'nope');
      expectRejected((j) => (j['score_rules'] as List)[0]['regex'] = '(');
    });

    test('non-JSON input is rejected', () {
      expect(() => Rules.parse('not json'), throwsA(isA<RulesException>()));
      expect(() => Rules.parse('[]'), throwsA(isA<RulesException>()));
    });
  });
}

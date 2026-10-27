import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/pipeline/classifier.dart';
import 'package:good_news/pipeline/dedupe.dart';
import 'package:good_news/pipeline/rules.dart';

DedupeDoc doc(String id, String title, {int hoursAgo = 0}) =>
    DedupeDoc(id: id, title: title, publishedAt: DateTime.utc(2026, 10, 27, 12).subtract(Duration(hours: hoursAgo)));

void main() {
  group('titleTokens', () {
    test('lowercases, drops stopwords and short words, stems plurals', () {
      expect(titleTokens('The Mussels are Threatened: 5 New Species!'), {'mussel', 'threatened', 'specie'}); // 1-char tokens dropped
      expect(titleTokens('500 mayors'), {'500', 'mayor'});
      expect(titleTokens('3D-printed beaks'), {'3d', 'printed', 'beak'});
    });
    test('keeps non-ASCII letters', () => expect(titleTokens('Café owners in Zürich'), {'café', 'owner', 'zürich'}));
    test('"ss" endings keep their s', () => expect(titleTokens('Progress'), {'progress'}));
  });

  group('clusterDuplicates', () {
    test('identical and near-identical headlines are merged (tier A)', () {
      final out = clusterDuplicates([
        doc('a', 'Hungary repeals anti-LGBTQ law, unlocking billions in EU funds', hoursAgo: 5),
        doc('b', 'Hungary repeals anti-LGBTQ law and unlocks billions in EU funds', hoursAgo: 2),
      ]);
      expect(out, {'a': 'a', 'b': 'a'}); // cluster id = earliest member
    });

    test('same story in different words is merged when rare words are shared (tier B)', () {
      final out = clusterDuplicates([
        doc('a', 'Wildlife vets give rare hornbill 3D-printed beak in world-first', hoursAgo: 30),
        doc('b', 'Meet the World’s First Bird With 3D-Printed Upper and Lower Beak Prostheses', hoursAgo: 20),
        ...[
          for (var i = 0; i < 12; i++) doc('f$i', 'Filler story number $i about unrelated topic ${i * 7}', hoursAgo: 10 + i),
        ],
      ]);
      expect(out['a'], out['b']);
      expect(out['a'], isNotNull);
    });

    test('unrelated stories that merely share generic words are not merged', () {
      final out = clusterDuplicates([
        doc('a', 'Flagship restoration project in Brazil’s Cerrado savannah', hoursAgo: 4),
        doc('b', '‘World’s largest deforestation project’ halted early', hoursAgo: 3),
        doc('c', 'The world’s largest battery-electric ferry just crossed an ocean', hoursAgo: 2),
      ]);
      expect(out, isEmpty);
    });

    test('pairs further apart than the window are never merged', () {
      final out = clusterDuplicates([
        doc('a', 'Hungary repeals anti-LGBTQ law, unlocking billions in EU funds', hoursAgo: 24 * 10),
        doc('b', 'Hungary repeals anti-LGBTQ law, unlocking billions in EU funds', hoursAgo: 1),
      ]);
      expect(out, isEmpty);
    });

    test('very short titles are never merged by tier A', () {
      expect(clusterDuplicates([doc('a', 'Inspiration'), doc('b', 'Inspiration')]), isEmpty);
    });

    test('clusters are transitive and the earliest member is the cluster id', () {
      final out = clusterDuplicates([
        doc('c', 'Ethiopia Green Legacy Initiative is turning citizens into foresters', hoursAgo: 1),
        doc('a', 'Ethiopia Green Legacy Initiative is turning citizens into foresters today', hoursAgo: 40),
        doc('b', 'Ethiopia Green Legacy Initiative turning citizens into foresters', hoursAgo: 20),
      ]);
      expect(out, {'a': 'a', 'b': 'a', 'c': 'a'});
    });

    test('empty and single inputs', () {
      expect(clusterDuplicates(const []), isEmpty);
      expect(clusterDuplicates([doc('a', 'Only one')]), isEmpty);
    });

    test('result does not depend on input order', () {
      final docs = [
        doc('a', 'Hungary repeals anti-LGBTQ law, unlocking billions in EU funds', hoursAgo: 5),
        doc('b', 'Hungary repeals anti-LGBTQ law and unlocks billions in EU funds', hoursAgo: 2),
        doc('c', 'Something entirely different happened today', hoursAgo: 1),
      ];
      expect(clusterDuplicates(docs.reversed.toList()), clusterDuplicates(docs));
    });
  });

  group('labeled duplicate groups (data/seed_labels.jsonl)', () {
    final rules = Rules.parse(File('assets/rules/rules.json').readAsStringSync());
    final trust = {
      for (final s in (jsonDecode(File('assets/sources.json').readAsStringSync())['sources'] as List))
        s['name'] as String: (s['trust_score'] as num).toDouble(),
    };
    final rows = File('../data/seed_labels.jsonl')
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .map((l) => jsonDecode(l) as Map<String, dynamic>)
        .toList();

    // The pool the de-duplicator actually sees: stories the classifier would show.
    final pool = <int>[
      for (var i = 0; i < rows.length; i++)
        if (classify(
              ClassifierItem(
                source: rows[i]['source'] as String,
                title: rows[i]['title'] as String,
                excerpt: (rows[i]['excerpt'] as String?) ?? '',
                url: rows[i]['url'] as String,
                publishedAt: DateTime.parse(rows[i]['published_at'] as String),
                sourceTrust: trust[rows[i]['source']] ?? 0.5,
              ),
              rules,
            ).route !=
            routeExcluded)
          i,
    ];
    final clusters = clusterDuplicates([
      for (final i in pool)
        DedupeDoc(id: '$i', title: rows[i]['title'] as String, publishedAt: DateTime.parse(rows[i]['published_at'] as String)),
    ]);
    final groups = <String, List<int>>{};
    for (var i = 0; i < rows.length; i++) {
      final g = rows[i]['duplicate_group'] as String?;
      if (g != null) groups.putIfAbsent(g, () => []).add(i);
    }

    test('no false merges: every cluster lies inside one labeled duplicate group', () {
      final byCluster = <String, Set<String?>>{};
      clusters.forEach((id, cluster) {
        byCluster.putIfAbsent(cluster, () => {}).add(rows[int.parse(id)]['duplicate_group'] as String?);
      });
      for (final e in byCluster.entries) {
        expect(e.value.length, 1, reason: 'cluster ${e.key} mixes groups ${e.value}');
        expect(e.value.single, isNotNull, reason: 'cluster ${e.key} merged unlabeled stories');
      }
    });

    test('detects the hornbill-beak pair', () {
      final ids = groups['hornbill-beak']!.map((i) => '$i');
      expect(ids.every(clusters.containsKey), isTrue);
      expect(clusters[ids.first], clusters[ids.last]);
    });

    test('known limitation: the mussel pair (same story, different framing) is not merged', () {
      // If this starts failing the detector improved: update docs/evaluation-report.md.
      final ids = groups['mussel-species']!.map((i) => '$i').toList();
      expect(clusters.containsKey(ids.first) && clusters[ids.first] == clusters[ids.last], isFalse);
    });

    test('the third labeled pair has a member the classifier excludes, so it never reaches the de-duplicator', () {
      final ids = groups['shanghai-opera']!;
      expect(ids.where(pool.contains).length, lessThan(2));
    });
  });
}

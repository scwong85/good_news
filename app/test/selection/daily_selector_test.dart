import 'dart:math' show Random;

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/selection/daily_selector.dart';

final now = DateTime.utc(2026, 10, 27, 12);

PickCandidate cand(
  String id, {
  String source = 's1',
  String route = 'today',
  double score = 0.6,
  double trust = 0.8,
  int hoursOld = 2,
  List<String> topics = const ['environment'],
  String? cluster,
  bool seen = false,
  bool hidden = false,
}) {
  return PickCandidate(
    id: id,
    sourceId: source,
    route: route,
    trustScore: trust,
    constructiveScore: score,
    publishedAt: now.subtract(Duration(hours: hoursOld)),
    topics: topics,
    clusterId: cluster,
    seen: seen,
    hidden: hidden,
  );
}

List<String> pick(
  List<PickCandidate> candidates, {
  int target = 5,
  List<PickCandidate> existing = const [],
  Set<String> topics = const {},
  Set<String> seenClusters = const {},
}) =>
    selectPicks(
      candidates: candidates,
      existing: existing,
      target: target,
      now: now,
      preferredTopics: topics,
      seenClusterKeys: seenClusters,
    );

/// Candidates with distinct sources and topics so caps never interfere.
List<PickCandidate> spread(int n, {String route = 'today', String prefix = 'x'}) => [
      for (var i = 0; i < n; i++)
        cand('$prefix$i', source: 'src$prefix$i', topics: ['t$prefix$i'], route: route, score: 0.8 - i * 0.01),
    ];

void main() {
  test('stories per day is clamped to 5..10', () {
    expect([clampStoriesPerDay(0), clampStoriesPerDay(5), clampStoriesPerDay(7), clampStoriesPerDay(10), clampStoriesPerDay(99)],
        [5, 5, 7, 10, 10]);
  });

  group('quota', () {
    test('returns exactly the missing number of stories when there are plenty', () {
      for (final target in [5, 7, 10]) {
        expect(pick(spread(20), target: target), hasLength(target));
      }
    });
    test('returns nothing when the quota is already met', () {
      final existing = spread(5, prefix: 'e');
      expect(pick(spread(10), existing: existing, target: 5), isEmpty);
      expect(pick(spread(10), existing: existing, target: 3), isEmpty);
    });
    test('extension returns only the new stories', () {
      final existing = spread(5, prefix: 'e');
      final more = pick(spread(10), existing: existing, target: 7);
      expect(more, hasLength(2));
      expect(more.toSet().intersection({for (final e in existing) e.id}), isEmpty);
    });
    test('returns fewer when there are not enough eligible stories', () {
      expect(pick(spread(3), target: 7), hasLength(3));
      expect(pick(const [], target: 5), isEmpty);
    });
  });

  group('tiers', () {
    test('today-route stories come before explore-route ones even if explore ranks higher', () {
      final out = pick([
        cand('t', route: 'today', score: 0.5, hoursOld: 100, source: 'a', topics: ['x']),
        cand('e', route: 'explore', score: 0.9, hoursOld: 0, source: 'b', topics: ['y']),
      ], target: 1);
      expect(out, ['t']);
    });
    test('explore fills the quota when there are too few today stories', () {
      final out = pick([...spread(2, prefix: 't'), ...spread(10, route: 'explore', prefix: 'e')], target: 5);
      expect(out.take(2), ['t0', 't1']);
      expect(out.skip(2).every((id) => id.startsWith('e')), isTrue);
      expect(out, hasLength(5));
    });
    test('excluded and unclassified routes are never picked', () {
      expect(pick([cand('a', route: 'excluded'), cand('b', route: '')], target: 5), isEmpty);
    });
  });

  group('eligibility', () {
    test('hidden, seen and too-old stories are skipped', () {
      final out = pick([
        cand('hidden', hidden: true),
        cand('seen', seen: true),
        cand('old', hoursOld: 24 * 15),
        cand('ok', hoursOld: 24 * 13),
      ]);
      expect(out, ['ok']);
    });
    test('stories already picked are not picked again', () {
      final existing = [cand('a')];
      expect(pick([cand('a'), cand('b', source: 'x', topics: ['y'])], existing: existing, target: 5), ['b']);
    });
  });

  group('diversity', () {
    test('at most two stories per source while others are available', () {
      final candidates = [
        for (var i = 0; i < 6; i++) cand('a$i', source: 'A', topics: ['ta$i'], score: 0.9),
        for (var i = 0; i < 4; i++) cand('b$i', source: 'B$i', topics: ['tb$i'], score: 0.3),
      ];
      final out = pick(candidates, target: 5);
      expect(out.where((id) => id.startsWith('a')), hasLength(2));
      expect(out, hasLength(5));
    });
    test('at most three stories per primary topic while others are available', () {
      final candidates = [
        for (var i = 0; i < 6; i++) cand('a$i', source: 'S$i', topics: ['env'], score: 0.9),
        for (var i = 0; i < 4; i++) cand('b$i', source: 'T$i', topics: ['tb$i'], score: 0.3),
      ];
      final out = pick(candidates, target: 6);
      expect(out.where((id) => id.startsWith('a')), hasLength(3));
    });
    test('the topic cap is relaxed before the source cap', () {
      final sameTopic = [for (var i = 0; i < 5; i++) cand('a$i', source: 'S$i', topics: ['env'])];
      expect(pick(sameTopic, target: 5), hasLength(5));
    });
    test('the source cap is relaxed last, only when there are too few stories', () {
      final oneSource = [for (var i = 0; i < 6; i++) cand('a$i', source: 'only', topics: ['t$i'], score: 0.9 - i * 0.01)];
      final out = pick(oneSource, target: 5);
      expect(out, hasLength(5));
      expect(out, ['a0', 'a1', 'a2', 'a3', 'a4']);
    });
    test('existing picks count toward the caps', () {
      final existing = [cand('e1', source: 'A', topics: ['x1']), cand('e2', source: 'A', topics: ['x2'])];
      final out = pick(
        [cand('a3', source: 'A', topics: ['x3'], score: 0.95), cand('b1', source: 'B', topics: ['y1'], score: 0.3)],
        existing: existing,
        target: 3,
      );
      expect(out, ['b1']); // A is capped; a3 is only taken if still needed (it is not)
    });
    test('stories without topics are not subject to the topic cap', () {
      final noTopic = [for (var i = 0; i < 5; i++) cand('a$i', source: 'S$i', topics: const [])];
      expect(pick(noTopic, target: 5), hasLength(5));
    });
  });

  group('duplicate clusters', () {
    test('only one story per cluster, the best ranked', () {
      final out = pick([
        cand('lo', cluster: 'k', score: 0.5, source: 'a', topics: ['x']),
        cand('hi', cluster: 'k', score: 0.9, source: 'b', topics: ['y']),
        cand('other', source: 'c', topics: ['z'], score: 0.4),
      ]);
      expect(out.where((id) => id == 'lo' || id == 'hi'), ['hi']);
    });
    test('a cluster already picked today is skipped', () {
      final existing = [cand('e', cluster: 'k')];
      expect(pick([cand('dup', cluster: 'k', source: 'x', topics: ['y'])], existing: existing, target: 5), isEmpty);
    });
    test('a cluster that has a seen story is skipped', () {
      expect(pick([cand('dup', cluster: 'k')], seenClusters: {'k'}), isEmpty);
    });
    test('the cluster root belongs to its own cluster (cluster id = earliest member id)', () {
      final out = pick([
        cand('a', cluster: 'a', score: 0.5, source: 's1', topics: ['x']),
        cand('b', cluster: 'a', score: 0.9, source: 's2', topics: ['y']),
      ]);
      expect(out, ['b']);
    });
  });

  group('preferences and determinism', () {
    test('preferred topics are boosted', () {
      final plain = cand('plain', source: 'a', topics: ['x'], score: 0.62);
      final liked = cand('liked', source: 'b', topics: ['health'], score: 0.60);
      expect(pick([plain, liked], target: 1), ['plain']);
      expect(pick([plain, liked], target: 1, topics: {'health'}), ['liked']);
    });
    test('the result does not depend on the input order', () {
      final candidates = [
        ...spread(8, prefix: 'a'),
        ...spread(8, route: 'explore', prefix: 'b'),
        cand('dupA', cluster: 'k', source: 'z1', topics: ['q1']),
        cand('dupB', cluster: 'k', source: 'z2', topics: ['q2']),
      ];
      final expected = pick(candidates, target: 10);
      for (var seed = 0; seed < 25; seed++) {
        final shuffled = [...candidates]..shuffle(_Rng(seed));
        expect(pick(shuffled, target: 10), expected, reason: 'seed $seed');
      }
    });
    test('equal ranks are broken by newest then id', () {
      final out = pick([
        cand('b', source: 'x', topics: ['x'], hoursOld: 2),
        cand('a', source: 'y', topics: ['y'], hoursOld: 2),
      ], target: 2);
      expect(out, ['a', 'b']);
    });
  });
}

class _Rng implements Random {
  _Rng(int seed) : _state = seed * 2654435761 + 12345;
  int _state;
  @override
  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % max;
  }

  @override
  double nextDouble() => nextInt(1 << 30) / (1 << 30);
  @override
  bool nextBool() => nextInt(2) == 1;
}

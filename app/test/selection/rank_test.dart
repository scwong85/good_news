import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/selection/rank.dart';

final now = DateTime.utc(2026, 10, 27, 12);

RankInput input({
  double trust = 0.8,
  double score = 0.5,
  int hoursOld = 0,
  List<String> topics = const [],
  bool seen = false,
  double sourcePenalty = 0,
}) =>
    RankInput(
      trustScore: trust,
      constructiveScore: score,
      publishedAt: now.subtract(Duration(hours: hoursOld)),
      topics: topics,
      seen: seen,
      sourcePenalty: sourcePenalty,
    );

double rank(RankInput i, {Set<String> topics = const {}}) => rankScore(i, now: now, preferredTopics: topics);

void main() {
  test('fresher stories rank higher, with a 36 hour half-life', () {
    expect(rank(input(hoursOld: 1)), greaterThan(rank(input(hoursOld: 30))));
    final fresh = rank(input());
    final half = rank(input(hoursOld: 36));
    expect(fresh - half, closeTo(0.25 * 0.5, 1e-9));
  });
  test('higher trust and higher constructive score rank higher', () {
    expect(rank(input(trust: 0.95)), greaterThan(rank(input(trust: 0.6))));
    expect(rank(input(score: 0.7)), greaterThan(rank(input(score: 0.45))));
  });
  test('weights are as documented', () {
    const w = RankWeights();
    expect(rank(input(trust: 1, score: 1)) - rank(input(trust: 0, score: 0)), closeTo(w.trust + w.constructive, 1e-9));
  });
  test('topic match boosts up to two matches', () {
    final base = rank(input(topics: ['environment', 'science', 'health']));
    final one = rank(input(topics: ['environment', 'science', 'health']), topics: {'environment'});
    final three = rank(input(topics: ['environment', 'science', 'health']), topics: {'environment', 'science', 'health'});
    expect(one - base, closeTo(0.1, 1e-9));
    expect(three - base, closeTo(0.2, 1e-9)); // capped at two
  });
  test('seen stories and penalized sources rank lower', () {
    expect(rank(input(seen: true)), lessThan(rank(input())));
    expect(rank(input(sourcePenalty: 0.2)), closeTo(rank(input()) - 0.2, 1e-9));
  });
  test('future-dated stories are not treated as fresher than now', () {
    expect(rank(input(hoursOld: -48)), closeTo(rank(input()), 1e-9));
  });
}

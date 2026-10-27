/// Story ranking (docs/architecture.md). Deterministic; never optimizes for engagement.
///
/// rank = trust + freshness + constructive_score + topic_match - seen_penalty - source_penalty
library;

import 'dart:math' as math;

class RankWeights {
  const RankWeights({
    this.trust = 0.25,
    this.freshness = 0.25,
    this.constructive = 0.40,
    this.topicMatch = 0.10,
    this.maxTopicMatches = 2,
    this.freshnessHalfLifeHours = 36,
    this.seenPenalty = 0.30,
  });

  final double trust;
  final double freshness;
  final double constructive;
  final double topicMatch;
  final int maxTopicMatches;
  final double freshnessHalfLifeHours;
  final double seenPenalty;
}

class RankInput {
  const RankInput({
    required this.trustScore,
    required this.constructiveScore,
    required this.publishedAt,
    required this.topics,
    this.seen = false,
    this.sourcePenalty = 0,
  });

  final double trustScore;
  final double constructiveScore;
  final DateTime publishedAt;
  final List<String> topics;
  final bool seen;

  /// Reader-specific penalty for the source (for example repeated "not credible" reports).
  final double sourcePenalty;
}

double rankScore(
  RankInput input, {
  required DateTime now,
  Set<String> preferredTopics = const {},
  RankWeights weights = const RankWeights(),
}) {
  final ageHours = math.max(0, now.difference(input.publishedAt).inMinutes) / 60.0;
  final freshness = math.pow(0.5, ageHours / weights.freshnessHalfLifeHours).toDouble();
  final matches = input.topics.where(preferredTopics.contains).length;
  return weights.trust * input.trustScore +
      weights.freshness * freshness +
      weights.constructive * input.constructiveScore +
      weights.topicMatch * math.min(matches, weights.maxTopicMatches) -
      (input.seen ? weights.seenPenalty : 0) -
      input.sourcePenalty;
}

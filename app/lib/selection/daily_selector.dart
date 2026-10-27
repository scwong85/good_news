/// Chooses a day's picks. Pure and deterministic (docs/architecture.md, "Daily selection").
library;

import '../pipeline/classifier.dart';
import 'rank.dart';

const minStoriesPerDay = 5;
const maxStoriesPerDay = 10;
const defaultStoriesPerDay = 5;

int clampStoriesPerDay(int n) => n.clamp(minStoriesPerDay, maxStoriesPerDay);

class PickCandidate {
  const PickCandidate({
    required this.id,
    required this.sourceId,
    required this.route,
    required this.trustScore,
    required this.constructiveScore,
    required this.publishedAt,
    required this.topics,
    this.clusterId,
    this.seen = false,
    this.hidden = false,
  });

  final String id;
  final String sourceId;
  final String route;
  final double trustScore;
  final double constructiveScore;
  final DateTime publishedAt;
  final List<String> topics;
  final String? clusterId;
  final bool seen;
  final bool hidden;

  String get primaryTopic => topics.isEmpty ? '' : topics.first;
  String get clusterKey => clusterId ?? id;
}

class SelectorConfig {
  const SelectorConfig({
    this.maxPerSource = 2,
    this.maxPerTopic = 3,
    this.ageWindowDays = 14,
    this.weights = const RankWeights(),
  });

  final int maxPerSource;
  final int maxPerTopic;
  final int ageWindowDays;
  final RankWeights weights;
}

/// Returns the ids to append to today's picks so that `existing + result` reaches [target]
/// (fewer if there are not enough eligible stories).
///
/// Order of preference: `today`-route stories, then `explore`-route stories, each by rank, with
/// at most [SelectorConfig.maxPerSource] per source and [SelectorConfig.maxPerTopic] per primary
/// topic; if that is not enough the topic cap and then the source cap are relaxed. One story per
/// duplicate cluster; stories whose cluster was already picked or seen are skipped.
List<String> selectPicks({
  required List<PickCandidate> candidates,
  required List<PickCandidate> existing,
  required int target,
  required DateTime now,
  Set<String> preferredTopics = const {},
  Set<String> seenClusterKeys = const {},
  Map<String, double> sourcePenalties = const {},
  SelectorConfig config = const SelectorConfig(),
}) {
  final needed = target - existing.length;
  if (needed <= 0) return const [];

  final pickedIds = {for (final p in existing) p.id};
  final usedClusters = {for (final p in existing) p.clusterKey};
  final sourceCounts = <String, int>{};
  final topicCounts = <String, int>{};
  for (final p in existing) {
    sourceCounts[p.sourceId] = (sourceCounts[p.sourceId] ?? 0) + 1;
    if (p.primaryTopic.isNotEmpty) topicCounts[p.primaryTopic] = (topicCounts[p.primaryTopic] ?? 0) + 1;
  }

  final cutoff = now.subtract(Duration(days: config.ageWindowDays));
  final ranked = <(PickCandidate, double)>[];
  for (final c in candidates) {
    if (c.hidden || c.seen) continue;
    if (c.route != routeToday && c.route != routeExplore) continue;
    if (c.publishedAt.isBefore(cutoff) || pickedIds.contains(c.id)) continue;
    if (usedClusters.contains(c.clusterKey) || seenClusterKeys.contains(c.clusterKey)) continue;
    final score = rankScore(
      RankInput(
        trustScore: c.trustScore,
        constructiveScore: c.constructiveScore,
        publishedAt: c.publishedAt,
        topics: c.topics,
        sourcePenalty: sourcePenalties[c.sourceId] ?? 0,
      ),
      now: now,
      preferredTopics: preferredTopics,
      weights: config.weights,
    );
    ranked.add((c, score));
  }
  // Rank desc, then newest, then id: a total order, so input order never matters.
  ranked.sort((a, b) {
    final r = b.$2.compareTo(a.$2);
    if (r != 0) return r;
    final t = b.$1.publishedAt.compareTo(a.$1.publishedAt);
    return t != 0 ? t : a.$1.id.compareTo(b.$1.id);
  });
  final today = [for (final r in ranked) if (r.$1.route == routeToday) r.$1];
  final explore = [for (final r in ranked) if (r.$1.route == routeExplore) r.$1];

  final chosen = <PickCandidate>[];
  bool take(PickCandidate c, int sourceCap, int topicCap) {
    if (chosen.length >= needed || usedClusters.contains(c.clusterKey)) return false;
    if ((sourceCounts[c.sourceId] ?? 0) >= sourceCap) return false;
    if (c.primaryTopic.isNotEmpty && (topicCounts[c.primaryTopic] ?? 0) >= topicCap) return false;
    chosen.add(c);
    usedClusters.add(c.clusterKey);
    sourceCounts[c.sourceId] = (sourceCounts[c.sourceId] ?? 0) + 1;
    if (c.primaryTopic.isNotEmpty) topicCounts[c.primaryTopic] = (topicCounts[c.primaryTopic] ?? 0) + 1;
    return true;
  }

  const unlimited = 1 << 30;
  void pass(List<PickCandidate> list, int sourceCap, int topicCap) {
    for (final c in list) {
      if (chosen.length >= needed) return;
      take(c, sourceCap, topicCap);
    }
  }

  pass(today, config.maxPerSource, config.maxPerTopic); // 1. best today-route, caps on
  pass(explore, config.maxPerSource, config.maxPerTopic); // 2. fill from explore, caps on
  final all = [...today, ...explore];
  pass(all, config.maxPerSource, unlimited); // 3. relax the topic cap
  pass(all, unlimited, unlimited); // 4. relax the source cap
  return [for (final c in chosen) c.id];
}

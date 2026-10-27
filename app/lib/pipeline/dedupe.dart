/// Duplicate-story detection from titles (no embeddings; see decision #35).
///
/// Two high-precision tiers, evaluated for pairs published within [windowDays] of each other:
///  A. near-identical headlines: Jaccard similarity of the title token sets >= 0.6
///     (both titles need >= 3 tokens);
///  B. same story, different words: IDF-weighted cosine of the title tokens >= 0.30 AND at
///     least 2 shared "rare" tokens (document frequency <= 3 in the compared window).
/// A false merge hides a legitimate story, so thresholds favour precision over recall;
/// same-story pairs with different framing may be missed (see docs/evaluation-report.md).
library;

import 'dart:math' as math;

class DedupeDoc {
  const DedupeDoc({required this.id, required this.title, required this.publishedAt});
  final String id;
  final String title;
  final DateTime publishedAt;
}

const _stopwords = {
  'a', 'an', 'the', 'and', 'or', 'but', 'of', 'in', 'on', 'at', 'to', 'for', 'from', 'by',
  'with', 'as', 'is', 'are', 'was', 'were', 'be', 'been', 'it', 'its', 'this', 'that',
  'these', 'those', 'their', 'his', 'her', 'our', 'your', 'you', 'we', 'they', 'he', 'she',
  'i', 'not', 'no', 'new', 'how', 'what', 'why', 'when', 'where', 'who', 'which', 'will',
  'can', 'could', 'would', 'should', 'may', 'more', 'most', 'than', 'then', 'so', 'up',
  'out', 'about', 'into', 'over', 'after', 'before', 'just', 'now', 'also', 'one', 'two', //
};

final _word = RegExp(r'[\p{L}\p{N}]+', unicode: true);

/// Lowercased content words with a light plural stemmer ("mussels" -> "mussel").
Set<String> titleTokens(String title) {
  final out = <String>{};
  for (final m in _word.allMatches(title.toLowerCase())) {
    var t = m.group(0)!;
    if (t.length < 2 || _stopwords.contains(t)) continue;
    if (t.length > 3 && t.endsWith('s') && !t.endsWith('ss')) t = t.substring(0, t.length - 1);
    out.add(t);
  }
  return out;
}

double jaccard(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final inter = a.intersection(b).length;
  return inter / (a.length + b.length - inter);
}

/// Maps article id -> cluster id for every article that has at least one duplicate.
/// The cluster id is the id of its earliest-published member (ties: smaller id).
/// Singletons are not included.
Map<String, String> clusterDuplicates(
  List<DedupeDoc> docs, {
  int windowDays = 3,
  double jaccardThreshold = 0.6,
  double cosineThreshold = 0.30,
  int rareDf = 3,
  int minRareShared = 2,
}) {
  if (docs.length < 2) return const {};
  final sorted = [...docs]..sort((a, b) {
      final c = a.publishedAt.compareTo(b.publishedAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  final tokens = [for (final d in sorted) titleTokens(d.title)];
  final df = <String, int>{};
  for (final set in tokens) {
    for (final t in set) {
      df[t] = (df[t] ?? 0) + 1;
    }
  }
  final n = sorted.length;
  double idf(String t) => math.log((n + 1) / (df[t]! + 1)) + 1;
  final norms = [
    for (final set in tokens) math.sqrt(set.fold<double>(0, (s, t) => s + idf(t) * idf(t))),
  ];

  final parent = List<int>.generate(n, (i) => i);
  int find(int i) {
    while (parent[i] != i) {
      parent[i] = parent[parent[i]];
      i = parent[i];
    }
    return i;
  }

  void union(int a, int b) {
    final ra = find(a), rb = find(b);
    if (ra == rb) return;
    // Keep the earlier document (lower index in time order) as the root.
    if (ra < rb) {
      parent[rb] = ra;
    } else {
      parent[ra] = rb;
    }
  }

  final window = Duration(days: windowDays);
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      if (sorted[j].publishedAt.difference(sorted[i].publishedAt) > window) break;
      final a = tokens[i], b = tokens[j];
      if (a.isEmpty || b.isEmpty) continue;
      if (a.length >= 3 && b.length >= 3 && jaccard(a, b) >= jaccardThreshold) {
        union(i, j);
        continue;
      }
      final shared = a.intersection(b);
      if (shared.length < minRareShared) continue;
      if (shared.where((t) => df[t]! <= rareDf).length < minRareShared) continue;
      final dot = shared.fold<double>(0, (s, t) => s + idf(t) * idf(t));
      if (dot / (norms[i] * norms[j]) >= cosineThreshold) union(i, j);
    }
  }

  final out = <String, String>{};
  final sizes = <int, int>{};
  for (var i = 0; i < n; i++) {
    sizes[find(i)] = (sizes[find(i)] ?? 0) + 1;
  }
  for (var i = 0; i < n; i++) {
    final root = find(i);
    if (sizes[root]! > 1) out[sorted[i].id] = sorted[root].id;
  }
  return out;
}

import '../data/db/app_database.dart';
import '../pipeline/dedupe.dart';

/// Assigns `cluster_id` to duplicate stories among recent shown-eligible articles.
class DedupeService {
  DedupeService(this.db, {DateTime Function()? now, this.lookbackDays = 8}) : _now = now ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _now;

  /// Articles older than this are left as they are (clustering only compares neighbours
  /// within a few days, so older assignments are stable).
  final int lookbackDays;

  /// Recomputes clusters for the lookback window. Returns how many articles changed.
  Future<int> refreshClusters() async {
    final since = _now().toUtc().subtract(Duration(days: lookbackDays));
    final rows = await db.clusterableArticles(since);
    final clusters = clusterDuplicates([
      for (final r in rows) DedupeDoc(id: r.id, title: r.title, publishedAt: r.publishedAt),
    ]);
    final changes = <String, String?>{};
    for (final r in rows) {
      final next = clusters[r.id];
      if (r.clusterId != next) changes[r.id] = next;
    }
    await db.setClusterIds(changes);
    return changes.length;
  }
}

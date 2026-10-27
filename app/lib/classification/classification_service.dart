import '../data/db/app_database.dart';
import '../pipeline/classifier.dart';
import '../pipeline/normalize.dart';
import '../pipeline/rules.dart';

/// Applies the bundled rules to articles (`after_classify` hook: stores route, score, tags and
/// the explanation together with the rules version).
class ClassificationService {
  ClassificationService(this.db, this.rules, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final AppDatabase db;
  final Rules rules;
  final DateTime Function() _now;

  /// Classifies a freshly normalized item from [source].
  Classification classifyNew(NormalizedItem item, SourceRow source) => classify(
        ClassifierItem(
          source: source.name,
          title: item.title,
          excerpt: item.excerpt,
          url: item.canonicalUrl,
          publishedAt: item.publishedAt,
          sourceTrust: source.trustScore,
          language: item.language,
        ),
        rules,
        now: _now().toUtc(),
      );

  /// Re-classifies stored articles that were classified with another rules version (after an
  /// app update) or never classified. Returns how many were updated.
  Future<int> reclassifyOutdated() async {
    final stale = await db.articlesNeedingClassification(rules.version);
    final now = _now().toUtc();
    for (final (article, source) in stale) {
      final c = classify(
        ClassifierItem(
          source: source.name,
          title: article.title,
          excerpt: article.excerpt,
          url: article.canonicalUrl,
          publishedAt: article.publishedAt,
          sourceTrust: source.trustScore,
          language: article.language,
        ),
        rules,
        now: now,
      );
      // Feed-category topics were merged in at insert time; keep them when re-merging.
      await db.updateClassification(article.id, c, article.topics);
    }
    return stale.length;
  }
}

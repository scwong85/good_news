import 'dart:convert';

import '../../data/db/app_database.dart';

/// A story as the UI sees it: an article plus its source, or a saved snapshot of one.
class Story {
  const Story({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.url,
    required this.sourceId,
    required this.sourceName,
    required this.publishedAt,
    this.topics = const [],
    this.storyTypes = const [],
    this.evidenceSignals = const [],
    this.route,
    this.score,
    this.rulesVersion,
    this.explanationJson,
    this.saved = false,
    this.fromSnapshot = false,
  });

  factory Story.fromRows(ArticleRow a, SourceRow s, {bool saved = false}) => Story(
        id: a.id,
        title: a.title,
        excerpt: a.excerpt,
        url: a.canonicalUrl,
        sourceId: a.sourceId,
        sourceName: s.name,
        publishedAt: a.publishedAt,
        topics: a.topics,
        storyTypes: a.storyTypes,
        evidenceSignals: a.evidenceSignals,
        route: a.route,
        score: a.constructiveScore,
        rulesVersion: a.rulesVersion,
        explanationJson: a.explanation,
        saved: saved,
      );

  factory Story.fromSnapshot(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return Story(
      id: m['id'] as String,
      title: m['title'] as String,
      excerpt: (m['excerpt'] as String?) ?? '',
      url: m['url'] as String,
      sourceId: (m['source_id'] as String?) ?? '',
      sourceName: (m['source_name'] as String?) ?? '',
      publishedAt: DateTime.parse(m['published_at'] as String),
      topics: List<String>.from((m['topics'] as List?) ?? const []),
      storyTypes: List<String>.from((m['story_types'] as List?) ?? const []),
      evidenceSignals: List<String>.from((m['evidence_signals'] as List?) ?? const []),
      route: m['route'] as String?,
      score: (m['score'] as num?)?.toDouble(),
      rulesVersion: m['rules_version'] as String?,
      explanationJson: m['explanation'] as String?,
      saved: true,
      fromSnapshot: true,
    );
  }

  final String id;
  final String title;
  final String excerpt;
  final String url;
  final String sourceId;
  final String sourceName;
  final DateTime publishedAt;
  final List<String> topics;
  final List<String> storyTypes;
  final List<String> evidenceSignals;
  final String? route;
  final double? score;
  final String? rulesVersion;

  /// Raw JSON from the classifier (`{"reason": ..., "rules": [...]}`), if any.
  final String? explanationJson;
  final bool saved;
  final bool fromSnapshot;

  Story copyWith({bool? saved}) => Story(
        id: id,
        title: title,
        excerpt: excerpt,
        url: url,
        sourceId: sourceId,
        sourceName: sourceName,
        publishedAt: publishedAt,
        topics: topics,
        storyTypes: storyTypes,
        evidenceSignals: evidenceSignals,
        route: route,
        score: score,
        rulesVersion: rulesVersion,
        explanationJson: explanationJson,
        saved: saved ?? this.saved,
        fromSnapshot: fromSnapshot,
      );

  /// What is stored when the reader saves the story. Only the headline, the short feed excerpt,
  /// attribution and the link to the original (never article text).
  String toSnapshot() => jsonEncode({
        'id': id,
        'title': title,
        'excerpt': excerpt,
        'url': url,
        'source_id': sourceId,
        'source_name': sourceName,
        'published_at': publishedAt.toUtc().toIso8601String(),
        'topics': topics,
        'story_types': storyTypes,
        'evidence_signals': evidenceSignals,
        'route': route,
        'score': score,
        'rules_version': rulesVersion,
        'explanation': explanationJson,
      });
}

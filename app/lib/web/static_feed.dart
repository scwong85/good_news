/// The static feed (docs/static-feed-contract.md): what the exporter writes and the web build
/// reads. Pure Dart, no I/O, so both sides share one definition and it can be tested.
library;

import '../domain/source.dart';
import '../pipeline/classifier.dart';
import '../pipeline/normalize.dart';

const staticFeedSchema = 1;

/// Files are written under this folder next to the web app: `feed/v1/...`.
const staticFeedDir = 'feed/v1';

/// A story as stored in the feed: the normalized item plus its classification for transparency
/// and inspection. The web app re-classifies locally with its own bundled rules, so the app and
/// the export can never disagree about a story.
class FeedArticle {
  FeedArticle({
    required this.id,
    required this.sourceId,
    required this.item,
    required this.classification,
  });

  final String id;
  final String sourceId;
  final NormalizedItem item;
  final Classification classification;

  Map<String, Object?> toJson() => {
        'id': id,
        'source_id': sourceId,
        'canonical_url': item.canonicalUrl,
        'title': item.title,
        'excerpt': item.excerpt,
        'published_at': item.publishedAt.toUtc().toIso8601String(),
        'language': item.language,
        'regions': item.regions,
        'topics': item.topics,
        'story_types': classification.storyTypes,
        'evidence_signals': classification.evidenceSignals,
        'constructive_score': classification.score,
        'route': classification.route,
        'explanation': classification.explanationJson(),
        'rules_version': classification.rulesVersion,
      };
}

/// Reads one article object. Returns null for objects that are unusable; never throws on bad
/// data, because one broken entry must not hide the rest of the feed.
NormalizedItem? normalizedItemFromJson(Object? json) {
  if (json is! Map) return null;
  try {
    final url = json['canonical_url'];
    final title = json['title'];
    final published = DateTime.tryParse('${json['published_at']}');
    if (url is! String || title is! String || published == null) return null;
    if (url.isEmpty || title.trim().isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) return null;
    var excerpt = (json['excerpt'] as String?) ?? '';
    if (excerpt.runes.length > excerptMaxChars) excerpt = truncate(excerpt, excerptMaxChars);
    return NormalizedItem(
      externalId: url,
      canonicalUrl: url,
      title: title.length > titleMax ? title.substring(0, titleMax) : title,
      excerpt: excerpt,
      publishedAt: published.toUtc(),
      language: (json['language'] as String?) ?? 'en',
      regions: [for (final r in (json['regions'] as List? ?? const [])) '$r'],
      topics: [for (final t in (json['topics'] as List? ?? const [])) '$t'],
    );
  } catch (_) {
    return null;
  }
}

class StaticManifest {
  StaticManifest({required this.generatedAt, required this.rulesVersion, required this.articles, required this.count});

  factory StaticManifest.fromJson(Object? json) {
    if (json is! Map || json['schema'] != staticFeedSchema) {
      throw const FormatException('unsupported feed schema');
    }
    final generated = DateTime.tryParse('${json['generated_at']}');
    if (generated == null) throw const FormatException('missing generated_at');
    return StaticManifest(
      generatedAt: generated.toUtc(),
      rulesVersion: '${json['rules_version'] ?? ''}',
      articles: [for (final a in (json['articles'] as List? ?? const [])) '$a'],
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  final DateTime generatedAt;
  final String rulesVersion;

  /// Paths relative to the feed folder, newest first.
  final List<String> articles;
  final int count;

  Map<String, Object?> toJson() => {
        'schema': staticFeedSchema,
        'generated_at': generatedAt.toUtc().toIso8601String(),
        'rules_version': rulesVersion,
        'articles': articles,
        'count': count,
      };

  /// The feed is considered stale after 48 hours (the UI then shows a quiet note).
  bool isStale(DateTime now) => now.difference(generatedAt) > const Duration(hours: 48);
}

/// The files of one export, keyed by path under [staticFeedDir].
class StaticFeedFiles {
  StaticFeedFiles(this.files);
  final Map<String, Object?> files;
}

/// Builds the feed files. Excluded stories are left out entirely; only the newest [keepDays]
/// publish days (UTC) are kept; within a day, newest first.
StaticFeedFiles buildStaticFeed({
  required List<FeedArticle> articles,
  required List<Source> sources,
  required String rulesVersion,
  required DateTime now,
  int keepDays = 14,
}) {
  final cutoff = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: keepDays - 1));
  final byDay = <String, List<FeedArticle>>{};
  final seen = <String>{};
  for (final a in articles) {
    if (a.classification.route == routeExcluded) continue;
    final published = a.item.publishedAt.toUtc();
    if (published.isBefore(cutoff)) continue;
    if (!seen.add(a.id)) continue;
    byDay.putIfAbsent(_day(published), () => []).add(a);
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  final files = <String, Object?>{};
  var count = 0;
  for (final day in days) {
    final list = byDay[day]!..sort((a, b) => b.item.publishedAt.compareTo(a.item.publishedAt));
    files['articles/$day.json'] = {'schema': staticFeedSchema, 'day': day, 'articles': [for (final a in list) a.toJson()]};
    count += list.length;
  }
  files['sources.json'] = {
    'schema': staticFeedSchema,
    'sources': [
      for (final s in sources)
        {'id': s.id, 'name': s.name, 'homepage_url': s.homepageUrl, 'tier': s.tier, 'language': s.language, 'regions': s.regions},
    ],
  };
  files['manifest.json'] = StaticManifest(
    generatedAt: now,
    rulesVersion: rulesVersion,
    articles: [for (final d in days) 'articles/$d.json'],
    count: count,
  ).toJson();
  return StaticFeedFiles(files);
}

String _day(DateTime utc) =>
    '${utc.year.toString().padLeft(4, '0')}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';

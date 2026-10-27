/// Turns a parsed feed entry into a normalized item. Pure Dart, no I/O.
/// Port of `tools/pipeline-prototype/ingestion/normalize.py` (see decision log #31 for the
/// differences: no language detection, no Unicode NFC normalization).
library;

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../domain/source.dart';
import 'canonicalize_url.dart';
import 'dates.dart';
import 'feed_parser.dart';

const titleMax = 500;
const excerptMaxChars = 300;

/// Feed category -> editorial topic (deterministic; the full topic rules arrive in Phase 4).
const topicAliases = {
  'environment': 'environment',
  'climate': 'environment',
  'nature': 'environment',
  'wildlife': 'environment',
  'conservation': 'environment',
  'science': 'science',
  'health': 'health',
  'medicine': 'health',
  'education': 'education',
  'technology': 'technology',
  'tech': 'technology',
  'community': 'community',
  'development': 'development',
  'society': 'society',
  'culture': 'culture',
};

/// Item cannot be ingested; [reason] is a short machine-readable code.
class SkipItem implements Exception {
  SkipItem(this.reason);
  final String reason;
  @override
  String toString() => 'SkipItem($reason)';
}

class NormalizedItem {
  NormalizedItem({
    required this.externalId,
    required this.canonicalUrl,
    required this.title,
    required this.excerpt,
    required this.publishedAt,
    required this.language,
    required this.regions,
    required this.topics,
  });

  final String externalId;
  final String canonicalUrl;
  final String title;
  final String excerpt;
  final DateTime publishedAt;
  final String language;
  final List<String> regions;
  final List<String> topics;
}

/// Strips markup, decodes entities and collapses whitespace.
String cleanText(String value) {
  if (value.isEmpty) return '';
  final fragment = html_parser.parseFragment(value);
  final parts = <String>[];
  void walk(dom.Node node) {
    if (node is dom.Text) {
      parts.add(node.data);
    } else {
      node.nodes.forEach(walk);
    }
  }

  fragment.nodes.forEach(walk);
  return parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Cuts [text] to at most [limit] characters on a word boundary and appends an ellipsis.
String truncate(String text, int limit) {
  final runes = text.runes.toList();
  if (runes.length <= limit) return text;
  final head = String.fromCharCodes(runes.sublist(0, limit));
  final space = head.lastIndexOf(' ');
  var cut = space < 0 ? head : head.substring(0, space);
  cut = cut.replaceFirst(RegExp(r'[ ,;:\-]+$'), '');
  return '$cut…';
}

final _wordPressBoilerplate = RegExp(r'\s*The post [\s\S]{0,500}? appeared first on [\s\S]*$');

String makeExcerpt(RawEntry entry, String title) {
  var raw = entry.summary ?? '';
  if (raw.isEmpty) raw = entry.content ?? '';
  var text = cleanText(raw).replaceAll(_wordPressBoilerplate, '').trim();
  if (text.startsWith(title)) text = text.substring(title.length).trim();
  return truncate(text, excerptMaxChars);
}

List<String> topicsFromCategories(List<String> categories) {
  final topics = <String>[];
  for (final category in categories) {
    final topic = topicAliases[category.trim().toLowerCase()];
    if (topic != null && !topics.contains(topic)) topics.add(topic);
  }
  return topics;
}

DateTime _publishedAt(RawEntry entry, DateTime now) {
  final date = parseFeedDate(entry.published) ?? parseFeedDate(entry.updated);
  if (date == null) throw SkipItem('missing_date');
  final limit = now.add(const Duration(days: 1)); // clamp far-future dates
  return date.isAfter(limit) ? limit : date;
}

NormalizedItem normalizeEntry(RawEntry entry, Source source, DateTime now) {
  final link = (entry.link ?? '').trim();
  if (link.isEmpty) throw SkipItem('missing_url');
  final String canonical;
  try {
    canonical = canonicalizeUrl(link);
  } on InvalidUrl {
    throw SkipItem('invalid_url');
  }
  final title = truncate(cleanText(entry.title ?? ''), titleMax);
  if (title.isEmpty) throw SkipItem('missing_title');
  final externalId = (entry.id?.isNotEmpty ?? false) ? entry.id! : link;
  return NormalizedItem(
    externalId: externalId.length > 1000 ? externalId.substring(0, 1000) : externalId,
    canonicalUrl: canonical,
    title: title,
    excerpt: makeExcerpt(entry, title),
    publishedAt: _publishedAt(entry, now),
    language: source.language,
    regions: List.of(source.regions),
    topics: topicsFromCategories(entry.categories),
  );
}

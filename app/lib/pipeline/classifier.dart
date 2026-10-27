/// Deterministic rule-based classifier. Port of `classifier/engine.py`; parity with the Python
/// reference is checked against `rules/golden_cases.jsonl` (see test/classification).
library;

import 'rules.dart';

const routeToday = 'today';
const routeExplore = 'explore';
const routeExcluded = 'excluded';

class ClassifierItem {
  const ClassifierItem({
    required this.source,
    required this.title,
    required this.excerpt,
    required this.url,
    required this.publishedAt,
    this.sourceTrust = 0.5,
    this.language,
  });

  final String source;
  final String title;
  final String excerpt;
  final String url;
  final DateTime? publishedAt;
  final double sourceTrust;

  /// null = unknown (skips the language check).
  final String? language;

  String get text => excerpt.isNotEmpty ? '$title. $excerpt' : title;

  /// The text a rule field matches against. Whitespace runs collapse to one space (like the
  /// Python reference); patterns have ASCII word/digit semantics in both implementations.
  String field(String name) => switch (name) {
        'title' => _collapse(title),
        'excerpt' => _collapse(excerpt),
        'url' => url,
        _ => _collapse(text),
      };
}

final _whitespace = RegExp(r'\s+');
String _collapse(String s) => s.replaceAll(_whitespace, ' ');

class ExplanationEntry {
  const ExplanationEntry(this.rule, this.group, this.weight, this.match);
  final String rule;
  final String group;
  final double weight;
  final String match;

  Map<String, Object?> toJson() => {'rule': rule, 'group': group, 'weight': weight, 'match': match};
}

class Classification {
  const Classification({
    required this.route,
    required this.score,
    required this.rulesVersion,
    this.reason = '',
    this.topics = const [],
    this.storyTypes = const [],
    this.evidenceSignals = const [],
    this.explanation = const [],
  });

  final String route;
  final double score;
  final String reason;
  final List<String> topics;
  final List<String> storyTypes;
  final List<String> evidenceSignals;
  final List<ExplanationEntry> explanation;
  final String rulesVersion;

  Map<String, Object?> explanationJson() => {
        'reason': reason,
        'rules': explanation.map((e) => e.toJson()).toList(),
      };
}

Classification classify(ClassifierItem item, Rules rules, {DateTime? now}) {
  final blocked = _stageOne(item, rules, now);
  if (blocked != null) {
    return Classification(route: routeExcluded, score: 0, reason: blocked, rulesVersion: rules.version);
  }

  final explanation = <ExplanationEntry>[];
  final groupTotals = {for (final g in rules.groupCaps.keys) g: 0.0};
  final groupHits = {for (final g in rules.groupCaps.keys) g: 0};
  final signals = <String>[];
  var veto = false;
  for (final rule in rules.scoreRules) {
    final m = rule.pattern.firstMatch(item.field(rule.field));
    if (m == null) continue;
    groupTotals[rule.group] = groupTotals[rule.group]! + rule.weight;
    groupHits[rule.group] = groupHits[rule.group]! + 1;
    final hit = m.group(0)!;
    explanation.add(ExplanationEntry(rule.id, rule.group, rule.weight, _firstRunes(hit, 60)));
    if (rule.signal != null && !signals.contains(rule.signal)) signals.add(rule.signal!);
    veto = veto || rule.veto;
  }

  var score = rules.baseScore;
  for (final entry in groupTotals.entries) {
    var total = entry.value;
    final cap = rules.groupCaps[entry.key];
    if (cap != null) total = cap >= 0 ? (total < cap ? total : cap) : (total > cap ? total : cap);
    score += total;
  }
  final prior = (item.sourceTrust - rules.trustCenter) * rules.sourcePriorScale;
  if (prior != 0) {
    explanation.add(ExplanationEntry('source_prior', 'source', _round6(prior), item.source));
  }
  score = _round6((score + prior).clamp(0.0, 1.0));

  final hasEvidence = signals.length >= rules.todayMinEvidence;
  final trusted = item.sourceTrust >= rules.todayTrustAtLeast;
  final hasVocabulary = rules.todayMinGroupMatches.entries.every((e) => (groupHits[e.key] ?? 0) >= e.value);

  String route;
  var reason = '';
  if (score >= rules.todayThreshold && !veto && hasVocabulary && (hasEvidence || trusted)) {
    route = routeToday;
  } else if (score >= rules.exploreThreshold) {
    route = routeExplore;
    if (score >= rules.todayThreshold) {
      reason = veto ? 'veto' : (!hasVocabulary ? 'no_vocabulary' : 'no_evidence');
    }
  } else {
    route = routeExcluded;
    reason = 'low_score';
  }

  final topics = _topNames(_keywordMatches(rules.topics, item), rules.maxTopics);
  var types = _topNames(_keywordMatches(rules.storyTypes, item), rules.maxStoryTypes);
  if (route != routeExcluded && types.isEmpty && rules.defaultStoryType != null) {
    types = [rules.defaultStoryType!];
  }
  return Classification(
    route: route,
    score: score,
    reason: reason,
    topics: topics,
    storyTypes: types,
    evidenceSignals: signals,
    explanation: explanation,
    rulesVersion: rules.version,
  );
}

String? _stageOne(ClassifierItem item, Rules rules, DateTime? now) {
  final uri = Uri.tryParse(item.url);
  final scheme = uri?.scheme.toLowerCase();
  if (uri == null || (scheme != 'http' && scheme != 'https') || uri.host.isEmpty) return 'invalid_url';
  if (item.title.trim().isEmpty) return 'missing_title';
  final allowed = rules.languageAllowlist;
  if (allowed != null && allowed.isNotEmpty && item.language != null && item.language!.isNotEmpty &&
      !allowed.contains(item.language)) {
    return 'unsupported_language';
  }
  if (item.publishedAt == null) return 'missing_date';
  final window = rules.ageWindowDays;
  if (now != null && window != null && window > 0 &&
      item.publishedAt!.isBefore(now.subtract(Duration(days: window)))) {
    return 'too_old';
  }
  final host = uri.host.toLowerCase();
  for (final dom in rules.blockedDomains) {
    if (host == dom || host.endsWith('.$dom')) return 'blocked_domain:$dom';
  }
  for (final rule in [...rules.globalExcludes, ...(rules.sourceExcludes[item.source] ?? const <ExcludeRule>[])]) {
    if (rule.pattern.hasMatch(item.field(rule.field))) return 'stage1:${rule.id}';
  }
  return null;
}

Map<String, int> _keywordMatches(Map<String, List<RegExp>> table, ClassifierItem item) {
  final text = item.field('text');
  final counts = <String, int>{};
  for (final entry in table.entries) {
    final n = entry.value.where((p) => p.hasMatch(text)).length;
    if (n > 0) counts[entry.key] = n;
  }
  return counts;
}

/// Highest count first; ties keep rules-file order (the map's insertion order).
List<String> _topNames(Map<String, int> counts, int limit) {
  final names = counts.keys.toList();
  final order = {for (var i = 0; i < names.length; i++) names[i]: i};
  names.sort((a, b) {
    final c = counts[b]!.compareTo(counts[a]!);
    return c != 0 ? c : order[a]!.compareTo(order[b]!);
  });
  return names.take(limit).toList();
}

double _round6(double x) => double.parse(x.toStringAsFixed(6));

String _firstRunes(String s, int n) {
  final runes = s.runes.toList();
  return runes.length <= n ? s : String.fromCharCodes(runes.sublist(0, n));
}

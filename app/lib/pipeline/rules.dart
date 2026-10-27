/// Loads and validates `rules/rules.json` (spec: docs/classification-rules.md).
/// Port of `tools/pipeline-prototype/classifier/engine.py`.
library;

import 'dart:convert';

class RulesException implements Exception {
  RulesException(this.message);
  final String message;
  @override
  String toString() => 'RulesException: $message';
}

const _fields = {'title', 'excerpt', 'text', 'url'};

RegExp _compile(String source, String flags) =>
    RegExp(source, caseSensitive: !flags.contains('i'));

class ScoreRule {
  ScoreRule({
    required this.id,
    required this.group,
    required this.field,
    required this.pattern,
    required this.weight,
    this.signal,
    this.veto = false,
  });
  final String id;
  final String group;
  final String field;
  final RegExp pattern;
  final double weight;
  final String? signal;
  final bool veto;
}

/// A Stage-1 exclusion (global or per source).
class ExcludeRule {
  ExcludeRule({required this.id, required this.field, required this.pattern});
  final String id;
  final String field;
  final RegExp pattern;
}

class Rules {
  Rules._({
    required this.version,
    required this.baseScore,
    required this.trustCenter,
    required this.sourcePriorScale,
    required this.ageWindowDays,
    required this.languageAllowlist,
    required this.todayThreshold,
    required this.exploreThreshold,
    required this.todayMinEvidence,
    required this.todayTrustAtLeast,
    required this.todayMinGroupMatches,
    required this.groupCaps,
    required this.maxTopics,
    required this.maxStoryTypes,
    required this.defaultStoryType,
    required this.blockedDomains,
    required this.globalExcludes,
    required this.sourceExcludes,
    required this.topics,
    required this.storyTypes,
    required this.scoreRules,
  });

  factory Rules.parse(String jsonText) {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } on FormatException catch (e) {
      throw RulesException('rules are not valid JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) throw RulesException('rules must be a JSON object');
    return Rules.fromJson(decoded);
  }

  factory Rules.fromJson(Map<String, dynamic> json) {
    for (final key in ['rules_version', 'base_score', 'thresholds', 'score_rules', 'groups']) {
      if (!json.containsKey(key)) throw RulesException("rules missing '$key'");
    }
    final groups = json['groups'] as Map<String, dynamic>;
    final caps = <String, double?>{
      for (final e in groups.entries) e.key: ((e.value as Map)['cap'] as num?)?.toDouble(),
    };

    final scoreRules = <ScoreRule>[];
    final ids = <String>{};
    for (final raw in json['score_rules'] as List) {
      final r = raw as Map<String, dynamic>;
      for (final key in ['id', 'group', 'field', 'regex', 'weight']) {
        if (!r.containsKey(key)) throw RulesException('score rule missing \'$key\': $r');
      }
      final id = r['id'] as String;
      if (!ids.add(id)) throw RulesException('duplicate rule id $id');
      if (!_fields.contains(r['field'])) throw RulesException('bad field in $id');
      if (!caps.containsKey(r['group'])) throw RulesException('unknown group in $id');
      scoreRules.add(ScoreRule(
        id: id,
        group: r['group'] as String,
        field: r['field'] as String,
        pattern: _compileOrThrow(id, r['regex'] as String, (r['flags'] as String?) ?? 'i'),
        weight: (r['weight'] as num).toDouble(),
        signal: r['signal'] as String?,
        veto: (r['veto'] as bool?) ?? false,
      ));
    }

    List<ExcludeRule> excludes(List<dynamic>? raw) => [
          for (final e in raw ?? const [])
            ExcludeRule(
              id: (e as Map)['id'] as String,
              field: e['field'] as String,
              pattern: _compileOrThrow(e['id'] as String, e['regex'] as String, (e['flags'] as String?) ?? 'i'),
            ),
        ];

    Map<String, List<RegExp>> tables(Map<String, dynamic>? raw) => {
          for (final e in (raw ?? const {}).entries)
            e.key: [for (final p in e.value as List) _compileOrThrow(e.key, p as String, 'i')],
        };

    final stage1 = (json['stage1'] as Map<String, dynamic>?) ?? const {};
    final need = (json['today_requires'] as Map<String, dynamic>?) ?? const {};
    final thresholds = json['thresholds'] as Map<String, dynamic>;
    return Rules._(
      version: json['rules_version'] as String,
      baseScore: (json['base_score'] as num).toDouble(),
      trustCenter: ((json['trust_center'] as num?) ?? 0.5).toDouble(),
      sourcePriorScale: ((json['source_prior_scale'] as num?) ?? 0.2).toDouble(),
      ageWindowDays: json['age_window_days'] as int?,
      languageAllowlist: (json['language_allowlist'] as List?)?.cast<String>(),
      todayThreshold: (thresholds['today'] as num).toDouble(),
      exploreThreshold: (thresholds['explore'] as num).toDouble(),
      todayMinEvidence: (need['min_evidence_signals'] as int?) ?? 0,
      todayTrustAtLeast: ((need['or_source_trust_at_least'] as num?) ?? 2.0).toDouble(),
      todayMinGroupMatches: ((need['min_group_matches'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, v as int)),
      groupCaps: caps,
      maxTopics: (json['max_topics'] as int?) ?? 3,
      maxStoryTypes: (json['max_story_types'] as int?) ?? 2,
      defaultStoryType: json['default_story_type'] as String?,
      blockedDomains: (stage1['blocked_domains'] as List?)?.cast<String>() ?? const [],
      globalExcludes: excludes(stage1['global_excludes'] as List?),
      sourceExcludes: {
        for (final e in ((stage1['source_excludes'] as Map?) ?? const {}).entries)
          e.key as String: excludes(e.value as List),
      },
      topics: tables(json['topics'] as Map<String, dynamic>?),
      storyTypes: tables(json['story_types'] as Map<String, dynamic>?),
      scoreRules: scoreRules,
    );
  }

  final String version;
  final double baseScore;
  final double trustCenter;
  final double sourcePriorScale;
  final int? ageWindowDays;
  final List<String>? languageAllowlist;
  final double todayThreshold;
  final double exploreThreshold;
  final int todayMinEvidence;
  final double todayTrustAtLeast;
  final Map<String, int> todayMinGroupMatches;
  final Map<String, double?> groupCaps;
  final int maxTopics;
  final int maxStoryTypes;
  final String? defaultStoryType;
  final List<String> blockedDomains;
  final List<ExcludeRule> globalExcludes;
  final Map<String, List<ExcludeRule>> sourceExcludes;
  final Map<String, List<RegExp>> topics;
  final Map<String, List<RegExp>> storyTypes;
  final List<ScoreRule> scoreRules;
}

RegExp _compileOrThrow(String id, String source, String flags) {
  try {
    return _compile(source, flags);
  } on FormatException catch (e) {
    throw RulesException('bad regex in $id: ${e.message}');
  }
}

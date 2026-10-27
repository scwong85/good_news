import 'dart:convert';

import '../shared/story.dart';

/// Plain-language explanation of why a story was included (docs/editorial-policy.md: every
/// story shows why it was chosen). Built only from what the classifier stored.
class WhyIncluded {
  const WhyIncluded({
    required this.headline,
    required this.reasons,
    required this.cautions,
    required this.footnote,
    this.detail,
  });

  final String headline;

  /// Up to four things the rules found in the headline/excerpt.
  final List<String> reasons;

  /// Things worth knowing (the rules also noticed these).
  final List<String> cautions;
  final String footnote;

  /// Technical line, for example "Score 0.67 · rules 2026.11.2".
  final String? detail;
}

const _reasonText = {
  'progress_terms': 'Reports progress or recovery',
  'reduce_terms': 'Describes something being reduced or improved',
  'protect_terms': 'Is about protection or conservation',
  'action_terms': 'Reports concrete action, such as a launch, funding or approval',
  'collab_terms': 'Involves people working together',
  'solution_terms': 'Describes a solution or programme',
  'success_terms': 'Reports a success or milestone',
  'clean_energy': 'Is about clean energy',
  'people_help': 'Is about helping people',
  'revival_terms': 'Is about bringing something back',
  'transform_terms': 'Is about transforming or reusing something',
  'tackle_terms': 'Is about tackling a problem',
  'access_terms': 'Is about widening access',
  'innovation_terms': 'Describes an innovation',
  'bridge_terms': 'Is about bringing people together',
  'sig_data': 'Cites figures or data',
  'sig_study': 'Refers to research',
  'sig_institution': 'Names an institution or organisation',
  'sig_official': 'Refers to official action or policy',
  'sig_outcome': 'Reports a measurable outcome',
};

const _cautionText = {
  'harm_terms': 'Mentions difficult events or problems',
  'harm_title': 'Mentions difficult events in the headline',
  'obstacle_terms': 'Also describes obstacles',
  'opinion': 'May be an opinion piece',
  'advocacy': 'May take an advocacy position',
  'listicle': 'Reads like a list',
  'how_to': 'Reads like advice or a guide',
  'advice_voice': 'Is written as advice to the reader',
  'question_title': 'Is phrased as a question',
  'clickbait': 'Uses attention-grabbing wording',
  'promo_terms': 'May be promotional',
  'animal_anecdote': 'Leans towards a light human-interest anecdote',
  'age_milestone': 'Leans towards a light human-interest anecdote',
  'celebrity_history': 'Leans towards a light human-interest anecdote',
  'quirky': 'Leans towards a light human-interest anecdote',
};

const _footnote =
    'Chosen automatically from the headline and excerpt using published rules. No person has '
    'checked this story, and it is not independently verified.';

WhyIncluded whyIncluded(Story story) {
  final rules = <Map<String, dynamic>>[];
  final raw = story.explanationJson;
  if (raw != null && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final r in (decoded['rules'] as List?) ?? const []) {
        rules.add(Map<String, dynamic>.from(r as Map));
      }
    } catch (_) {
      // An unreadable explanation just means fewer details.
    }
  }

  final headline = switch (story.route) {
    'today' => 'Highlighted today: it scored well against our criteria for constructive news.',
    'explore' => 'Included because it partly matches our criteria for constructive news. '
        'It did not reach the stricter bar for the top list.',
    _ => 'Saved from an earlier day.',
  };

  // Strongest positive findings first; stable order for ties.
  final positives = [
    for (final r in rules)
      if (_reasonText.containsKey(r['rule']) && (r['weight'] as num) > 0) r,
  ]..sort((a, b) => (b['weight'] as num).compareTo(a['weight'] as num));
  final reasons = <String>[];
  for (final r in positives) {
    final text = _reasonText[r['rule']]!;
    if (!reasons.contains(text)) reasons.add(text);
    if (reasons.length == 4) break;
  }

  final cautions = <String>[];
  for (final r in rules) {
    final text = _cautionText[r['rule']];
    if (text != null && !cautions.contains(text)) cautions.add(text);
    if (cautions.length == 2) break;
  }

  final detail = story.score == null
      ? null
      : 'Score ${story.score!.toStringAsFixed(2)}${story.rulesVersion == null ? '' : ' · rules ${story.rulesVersion}'}';
  return WhyIncluded(
    headline: headline,
    reasons: reasons,
    cautions: cautions,
    footnote: _footnote,
    detail: detail,
  );
}

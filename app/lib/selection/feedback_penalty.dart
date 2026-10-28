/// How reports lower a source's rank on this phone (the `negative_feedback_penalty` of the
/// ranking formula in docs/architecture.md). Reports never change what other readers see.
library;

const notCredibleSignal = 'not_credible';
const tooTrivialSignal = 'too_trivial';
const notForMeSignal = 'not_for_me';
const alreadySeenSignal = 'already_seen';

const maxSourcePenalty = 0.3;

/// 0.10 per "not credible" and 0.03 per "too trivial" report, at most 0.30. "Not for me" and
/// "already seen" hide the story but say nothing about the source.
Map<String, double> sourcePenaltiesFromFeedback(Map<String, Map<String, int>> countsBySource) => {
      for (final e in countsBySource.entries)
        if (_penalty(e.value) > 0) e.key: _penalty(e.value),
    };

double _penalty(Map<String, int> counts) {
  final raw = 0.10 * (counts[notCredibleSignal] ?? 0) + 0.03 * (counts[tooTrivialSignal] ?? 0);
  return raw > maxSourcePenalty ? maxSourcePenalty : double.parse(raw.toStringAsFixed(4));
}

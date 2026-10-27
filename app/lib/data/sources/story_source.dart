import '../../domain/source.dart';
import '../../pipeline/normalize.dart';

/// Conditional-request state remembered per source.
class FetchState {
  const FetchState({this.etag = '', this.lastModified = ''});
  final String etag;
  final String lastModified;
}

/// A normalized story plus, for pre-classified sources (future static JSON), its classification.
class Candidate {
  const Candidate(this.item, {this.precomputedClassification});
  final NormalizedItem item;
  final Map<String, Object?>? precomputedClassification;
}

class SourceResult {
  SourceResult({
    required this.candidates,
    this.itemsSeen = 0,
    this.itemsSkipped = 0,
    this.notModified = false,
    this.etag = '',
    this.lastModified = '',
    this.httpStatus,
  });
  final List<Candidate> candidates;
  final int itemsSeen;
  final int itemsSkipped;
  final bool notModified;
  final String etag;
  final String lastModified;
  final int? httpStatus;
}

/// Where stories come from. Android: [DirectRssStorySource]. Web (future milestone):
/// a static-JSON implementation reading `docs/static-feed-contract.md`.
///
/// Implementations throw `FetchFailure` / `FeedParseException` for source-level problems;
/// the ingestion service records them per source and keeps going.
abstract class StorySource {
  Future<SourceResult> load(Source source, {FetchState previous = const FetchState()});
}

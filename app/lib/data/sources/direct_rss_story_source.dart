import '../../domain/source.dart';
import '../../pipeline/feed_parser.dart';
import '../../pipeline/normalize.dart';
import '../http/feed_fetcher.dart';
import 'story_source.dart';

/// Fetches the source's RSS/Atom feed directly (Android; browsers block this for most feeds).
class DirectRssStorySource implements StorySource {
  DirectRssStorySource(this._fetcher, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final FeedFetcher _fetcher;
  final DateTime Function() _now;

  @override
  Future<SourceResult> load(Source source, {FetchState previous = const FetchState()}) async {
    final result = await _fetcher.fetch(
      Uri.parse(source.rssUrl),
      etag: previous.etag,
      lastModified: previous.lastModified,
    );
    if (result.notModified) {
      return SourceResult(
        candidates: const [],
        notModified: true,
        etag: result.etag,
        lastModified: result.lastModified,
        httpStatus: result.statusCode,
      );
    }
    final entries = parseFeed(result.bytes);
    final now = _now().toUtc();
    final candidates = <Candidate>[];
    var skipped = 0;
    for (final entry in entries) {
      try {
        candidates.add(Candidate(normalizeEntry(entry, source, now)));
      } on SkipItem {
        skipped++;
      } catch (_) {
        skipped++; // one bad item never fails the whole feed
      }
    }
    return SourceResult(
      candidates: candidates,
      itemsSeen: entries.length,
      itemsSkipped: skipped,
      etag: result.etag,
      lastModified: result.lastModified,
      httpStatus: result.statusCode,
    );
  }
}

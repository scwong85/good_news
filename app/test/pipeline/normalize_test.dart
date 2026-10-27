import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/domain/source.dart';
import 'package:good_news/pipeline/feed_parser.dart';
import 'package:good_news/pipeline/normalize.dart';

const source = Source(
  id: 'test',
  name: 'Test Source',
  homepageUrl: 'https://example.com',
  rssUrl: 'https://example.com/feed/',
  tier: 1,
  trustScore: 0.9,
  language: 'en',
  regions: ['global'],
);
final now = DateTime.utc(2026, 10, 27, 12);

RawEntry entry({
  String? title = 'A title',
  String? link = 'https://example.com/a',
  String? summary,
  String? content,
  String? published = 'Tue, 27 Oct 2026 07:00:17 GMT',
  List<String> categories = const [],
}) =>
    RawEntry(title: title, link: link, summary: summary, content: content, published: published, categories: categories);

void main() {
  group('cleanText', () {
    test('strips tags, decodes entities, collapses whitespace', () {
      expect(cleanText('<p>Hello&nbsp;<b>world</b> &amp; friends</p>\n\n  ok'), 'Hello world & friends ok');
    });
    test('plain text and empty input', () {
      expect(cleanText('Fish & chips'), 'Fish & chips');
      expect(cleanText(''), '');
    });
  });

  group('truncate', () {
    test('cuts on a word boundary and adds an ellipsis', () {
      final out = truncate('alpha beta gamma delta', 12);
      expect(out, 'alpha beta…');
      expect(out.runes.length <= 12, isTrue);
    });
    test('short text is untouched; counts characters not UTF-16 units', () {
      expect(truncate('short', 10), 'short');
      expect(truncate('😀😀😀😀', 4), '😀😀😀😀');
    });
    test('no space inside the limit keeps the head (Python parity)', () {
      expect(truncate('abcdefghij klm', 5), 'abcde…');
    });
  });

  group('normalizeEntry', () {
    test('full normalization', () {
      final item = normalizeEntry(
        entry(
          title: '  Wetlands <i>restored</i>  ',
          link: 'http://Example.com/wet/?utm_source=nl',
          summary: '<p>Volunteers restored 40 hectares of wetland. ${'More detail. ' * 40}</p>',
          categories: ['Environment', 'Weird Tag', 'Climate'],
        ),
        source,
        now,
      );
      expect(item.title, 'Wetlands restored');
      expect(item.canonicalUrl, 'https://example.com/wet');
      expect(item.excerpt.startsWith('Volunteers restored 40 hectares'), isTrue);
      expect(item.excerpt.runes.length <= excerptMaxChars + 1, isTrue);
      expect(item.topics, ['environment']);
      expect(item.regions, ['global']);
      expect(item.language, 'en');
      expect(item.publishedAt, DateTime.utc(2026, 10, 27, 7, 0, 17));
    });

    test('WordPress boilerplate and title echo are removed', () {
      final item = normalizeEntry(
        entry(
          title: 'Solar farms shelter owls',
          summary: 'Solar farms shelter owls Burrowing owls thrive. The post Solar farms shelter owls appeared first on Example.',
        ),
        source,
        now,
      );
      expect(item.excerpt, 'Burrowing owls thrive.');
    });

    test('excerpt falls back to content when there is no summary', () {
      final item = normalizeEntry(entry(summary: null, content: '<p>Only content.</p>'), source, now);
      expect(item.excerpt, 'Only content.');
    });

    test('skip reasons', () {
      void expectSkip(RawEntry e, String reason) {
        expect(() => normalizeEntry(e, source, now),
            throwsA(isA<SkipItem>().having((s) => s.reason, 'reason', reason)));
      }

      expectSkip(entry(published: null), 'missing_date');
      expectSkip(entry(published: 'not a date'), 'missing_date');
      expectSkip(entry(link: 'ftp://example.com/a'), 'invalid_url');
      expectSkip(entry(link: null), 'missing_url');
      expectSkip(entry(link: '   '), 'missing_url');
      expectSkip(entry(title: '   '), 'missing_title');
      expectSkip(entry(title: null), 'missing_title');
    });

    test('far-future dates are clamped to now + 1 day', () {
      final item = normalizeEntry(entry(published: 'Tue, 27 Oct 2036 07:00:17 GMT'), source, now);
      expect(item.publishedAt, now.add(const Duration(days: 1)));
    });

    test('external id prefers guid, falls back to link, and is capped', () {
      final withGuid = normalizeEntry(
        RawEntry(id: 'guid-1', title: 't', link: 'https://example.com/a', published: 'Tue, 27 Oct 2026 07:00:17 GMT'),
        source,
        now,
      );
      expect(withGuid.externalId, 'guid-1');
      expect(normalizeEntry(entry(), source, now).externalId, 'https://example.com/a');
    });
  });

  test('topicsFromCategories maps known aliases once', () {
    expect(topicsFromCategories(['Climate', 'environment', 'Tech', 'Nope']), ['environment', 'technology']);
  });
}

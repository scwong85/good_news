import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/pipeline/feed_parser.dart';

List<int> fixture(String name) => File('test/fixtures/feeds/$name').readAsBytesSync();

void main() {
  group('RSS', () {
    final entries = parseFeed(fixture('rss_wordpress.xml'));

    test('parses all items', () => expect(entries, hasLength(6)));

    test('reads core fields, CDATA, categories and content:encoded', () {
      final e = entries.first;
      expect(e.title, 'Wetlands restored by volunteers, study finds 40% more birds');
      expect(e.link, 'https://example.com/wetlands/?utm_source=newsletter');
      expect(e.id, 'https://example.com/?p=101');
      expect(e.published, 'Tue, 27 Oct 2026 07:00:17 +0000');
      expect(e.categories, ['Environment', 'Climate', 'Weird Tag']);
      expect(e.summary, contains('Volunteers restored 40 hectares'));
      expect(e.content, contains('FULL ARTICLE TEXT'));
    });

    test('ignores atom:link elements outside items and reads dc:date', () {
      expect(entries.last.published, '2026-10-26T12:30:00+02:00');
      expect(entries.last.link, 'https://example.com/dc');
    });
  });

  group('Atom', () {
    final entries = parseFeed(fixture('atom_basic.xml'));
    test('uses the alternate link, published/updated and category term', () {
      expect(entries, hasLength(2));
      expect(entries[0].link, 'https://example.com/atom/reefs/');
      expect(entries[0].published, '2026-10-26T08:00:00Z');
      expect(entries[0].updated, '2026-10-27T09:00:00Z');
      expect(entries[0].categories, ['Science']);
      expect(entries[0].summary, 'Coral cover grew 12% in five years.');
    });
    test('falls back to link without rel and content/updated only', () {
      expect(entries[1].link, 'https://example.com/atom/updated-only');
      expect(entries[1].published, isNull);
      expect(entries[1].updated, '2026-10-25T08:00:00-05:00');
      expect(entries[1].content, contains('Content as the only text'));
    });
  });

  group('tolerance', () {
    test('recovers bare ampersands, HTML named entities, control characters', () {
      final entries = parseFeed(fixture('rss_broken_but_recoverable.xml'));
      expect(entries, hasLength(1));
      expect(entries.single.title, 'Fish & chips cheaper — and Tom & Jerry return');
      expect(entries.single.link, 'https://example.com/sloppy?a=1&b=2');
      expect(entries.single.summary, contains('&unknownentity;'));
      expect(entries.single.summary, isNot(contains('\x07')));
    });
    test('BOM and ISO-8859-1', () {
      expect(parseFeed(fixture('rss_bom.xml')).single.title, 'BOM story');
      expect(parseFeed(fixture('rss_latin1.xml')).single.title, 'Café opens');
    });
    test('CDATA content is not entity-escaped twice', () {
      final entries = parseFeed(utf8.encode(
          '<rss version="2.0"><channel><item><title><![CDATA[Tom & Jerry &amp; co]]></title><link>https://e.com/x</link></item></channel></rss>'));
      expect(entries.single.title, 'Tom & Jerry &amp; co');
    });
  });

  group('failures', () {
    test('malformed XML throws FeedParseException', () {
      expect(() => parseFeed(fixture('malformed.xml')), throwsA(isA<FeedParseException>()));
    });
    test('HTML page and empty bytes throw', () {
      expect(() => parseFeed(fixture('not_a_feed.html')), throwsA(isA<FeedParseException>()));
      expect(() => parseFeed(const []), throwsA(isA<FeedParseException>()));
    });
    test('valid feed with no items returns an empty list', () {
      expect(parseFeed(fixture('empty.xml')), isEmpty);
    });
    test('unknown root element is rejected', () {
      expect(() => parseFeed(utf8.encode('<html><body/></html>')), throwsA(isA<FeedParseException>()));
    });
  });
}

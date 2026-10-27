/// RSS 2.0 / RSS 1.0 / Atom parsing with tolerance for common real-world breakage
/// (control characters, bare ampersands, HTML named entities, BOMs).
library;

import 'dart:convert';

import 'package:xml/xml.dart';

class FeedParseException implements Exception {
  FeedParseException(this.message);
  final String message;
  @override
  String toString() => 'FeedParseException: $message';
}

/// One feed entry as found in the XML. Dates are kept as raw strings (see `dates.dart`).
class RawEntry {
  RawEntry({
    this.id,
    this.title,
    this.link,
    this.summary,
    this.content,
    this.published,
    this.updated,
    this.categories = const [],
  });

  final String? id;
  final String? title;
  final String? link;
  final String? summary;
  final String? content;
  final String? published;
  final String? updated;
  final List<String> categories;
}

const _atomNs = 'http://www.w3.org/2005/Atom';
const _contentNs = 'http://purl.org/rss/1.0/modules/content/';
const _dcNs = 'http://purl.org/dc/elements/1.1/';

/// Parses feed [bytes]. Throws [FeedParseException] when no feed can be recovered.
List<RawEntry> parseFeed(List<int> bytes) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(_sanitize(_decode(bytes)));
  } on XmlException catch (e) {
    throw FeedParseException('unparseable feed: ${e.message}');
  }
  final root = doc.rootElement;
  final name = root.name.local.toLowerCase();
  if (name == 'feed') {
    return root.childElements.where((e) => e.name.local == 'entry').map(_atomEntry).toList();
  }
  if (name == 'rss' || name == 'rdf') {
    return root.descendantElements.where((e) => e.name.local == 'item').map(_rssItem).toList();
  }
  throw FeedParseException('not a feed (root element <${root.name.local}>)');
}

String _decode(List<int> bytes) {
  var data = bytes;
  if (data.length >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF) {
    data = data.sublist(3);
  }
  final head = latin1.decode(data.take(200).toList(), allowInvalid: true).toLowerCase();
  final declared = RegExp(r'encoding=["' "'" r']([a-z0-9_\-]+)').firstMatch(head)?.group(1);
  if (declared == 'iso-8859-1' || declared == 'latin1' || declared == 'windows-1252') {
    return latin1.decode(data, allowInvalid: true);
  }
  return utf8.decode(data, allowMalformed: true);
}

const _xmlEntities = {'amp', 'lt', 'gt', 'quot', 'apos'};
const _htmlEntities = {
  'nbsp': '&#160;', 'copy': '&#169;', 'reg': '&#174;', 'laquo': '&#171;', 'raquo': '&#187;',
  'ndash': '&#8211;', 'mdash': '&#8212;', 'lsquo': '&#8216;', 'rsquo': '&#8217;',
  'ldquo': '&#8220;', 'rdquo': '&#8221;', 'hellip': '&#8230;', 'bull': '&#8226;',
  'trade': '&#8482;', 'euro': '&#8364;', 'pound': '&#163;', 'eacute': '&#233;',
  'egrave': '&#232;', 'aacute': '&#225;', 'uuml': '&#252;', 'ouml': '&#246;', //
};
final _entity = RegExp(r'&(#\d+|#[xX][0-9a-fA-F]+|[A-Za-z][A-Za-z0-9]*);');
final _cdata = RegExp(r'<!\[CDATA\[[\s\S]*?\]\]>');
final _illegalChars = RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F￾￿]');

/// Fixes the usual causes of XML parse errors without touching CDATA sections.
String _sanitize(String text) {
  text = text.replaceAll(_illegalChars, '');
  final out = StringBuffer();
  var last = 0;
  for (final m in _cdata.allMatches(text)) {
    out.write(_fixEntities(text.substring(last, m.start)));
    out.write(m.group(0));
    last = m.end;
  }
  out.write(_fixEntities(text.substring(last)));
  return out.toString();
}

String _fixEntities(String s) {
  final result = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final amp = s.indexOf('&', i);
    if (amp < 0) {
      result.write(s.substring(i));
      break;
    }
    result.write(s.substring(i, amp));
    final m = _entity.matchAsPrefix(s, amp);
    if (m == null) {
      result.write('&amp;'); // bare ampersand
      i = amp + 1;
      continue;
    }
    final body = m.group(1)!;
    if (body.startsWith('#') || _xmlEntities.contains(body)) {
      result.write(m.group(0));
    } else if (_htmlEntities.containsKey(body)) {
      result.write(_htmlEntities[body]);
    } else {
      result.write('&amp;$body;'); // unknown named entity stays literal text
    }
    i = m.end;
  }
  return result.toString();
}

String? _text(XmlElement el, String local, {Set<String?> namespaces = const {null, ''}}) {
  for (final child in el.childElements) {
    if (child.name.local == local && namespaces.contains(child.name.namespaceUri)) {
      final value = child.innerText.trim();
      if (value.isNotEmpty) return value;
    }
  }
  return null;
}

RawEntry _rssItem(XmlElement item) {
  final categories = <String>[];
  for (final c in item.childElements.where((e) => e.name.local == 'category')) {
    final term = c.innerText.trim();
    if (term.isNotEmpty) categories.add(term);
  }
  return RawEntry(
    id: _text(item, 'guid'),
    title: _text(item, 'title'),
    link: _text(item, 'link'),
    summary: _text(item, 'description'),
    content: _text(item, 'encoded', namespaces: {_contentNs}),
    published: _text(item, 'pubDate') ?? _text(item, 'date', namespaces: {_dcNs}),
    updated: _text(item, 'updated', namespaces: {_atomNs}),
    categories: categories,
  );
}

RawEntry _atomEntry(XmlElement entry) {
  String? link;
  for (final l in entry.childElements.where((e) => e.name.local == 'link')) {
    final rel = l.getAttribute('rel');
    final href = l.getAttribute('href');
    if (href != null && (rel == null || rel == 'alternate')) {
      link = href.trim();
      break;
    }
  }
  const ns = {_atomNs};
  return RawEntry(
    id: _text(entry, 'id', namespaces: ns),
    title: _text(entry, 'title', namespaces: ns),
    link: link,
    summary: _text(entry, 'summary', namespaces: ns),
    content: _text(entry, 'content', namespaces: ns),
    published: _text(entry, 'published', namespaces: ns),
    updated: _text(entry, 'updated', namespaces: ns),
    categories: entry.childElements
        .where((e) => e.name.local == 'category')
        .map((e) => (e.getAttribute('term') ?? e.innerText).trim())
        .where((t) => t.isNotEmpty)
        .toList(),
  );
}

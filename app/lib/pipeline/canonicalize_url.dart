/// URL canonicalization. Port of `tools/pipeline-prototype/ingestion/urls.py`;
/// parity is checked against `test/fixtures/golden_urls.json`.
library;

import 'dart:convert';

class InvalidUrl implements Exception {
  InvalidUrl(this.message);
  final String message;
  @override
  String toString() => 'InvalidUrl: $message';
}

const _trackingParams = {
  'fbclid',
  'gclid',
  'dclid',
  'msclkid',
  'mc_cid',
  'mc_eid',
  'igshid',
  'mkt_tok',
  '_hsenc',
  '_hsmi',
  'ref_src',
  'ref_url',
  'yclid',
  'oly_enc_id',
  'oly_anon_id',
};
const _trackingPrefixes = ['utm_', 'pk_', 'vero_', 'hsa_'];

final _urlPattern = RegExp(
  r'^([A-Za-z][A-Za-z0-9+.\-]*):(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#.*)?$',
);

/// Returns a stable form of [url] or throws [InvalidUrl] for non-HTTP(S) or hostless URLs.
///
/// http is upgraded to https; host is lowercased; default ports (80, 443) are dropped;
/// the fragment and tracking parameters are removed; remaining parameters are sorted;
/// the trailing slash is removed except for the root path.
String canonicalizeUrl(String url) {
  final match = _urlPattern.firstMatch(url.trim());
  if (match == null) throw InvalidUrl('unsupported URL: $url');
  final scheme = match.group(1)!.toLowerCase();
  final authority = match.group(2);
  if ((scheme != 'http' && scheme != 'https') || authority == null) {
    throw InvalidUrl('unsupported URL: $url');
  }
  var hostPort = authority.substring(authority.lastIndexOf('@') + 1);
  String host;
  int? port;
  if (hostPort.startsWith('[')) {
    final end = hostPort.indexOf(']');
    if (end < 0) throw InvalidUrl('bad host: $url');
    host = hostPort.substring(0, end + 1);
    hostPort = hostPort.substring(end + 1);
    if (hostPort.startsWith(':')) port = _parsePort(hostPort.substring(1), url);
  } else {
    final colon = hostPort.lastIndexOf(':');
    if (colon >= 0) {
      port = _parsePort(hostPort.substring(colon + 1), url);
      host = hostPort.substring(0, colon);
    } else {
      host = hostPort;
    }
  }
  host = host.toLowerCase();
  while (host.endsWith('.')) {
    host = host.substring(0, host.length - 1);
  }
  if (host.isEmpty) throw InvalidUrl('missing host: $url');
  final netloc = (port == null || port == 80 || port == 443) ? host : '$host:$port';

  final query = _parseQuery(match.group(4) ?? '')
      .where((kv) {
        final key = kv.$1.toLowerCase();
        return !_trackingParams.contains(key) &&
            !_trackingPrefixes.any(key.startsWith);
      })
      .toList()
    ..sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0 ? c : a.$2.compareTo(b.$2);
    });

  var path = match.group(3) ?? '';
  if (path.isEmpty) path = '/';
  if (path.length > 1) {
    var end = path.length;
    while (end > 0 && path[end - 1] == '/') {
      end--;
    }
    path = end == 0 ? '/' : path.substring(0, end);
  }
  final q = query.map((kv) => '${_quotePlus(kv.$1)}=${_quotePlus(kv.$2)}').join('&');
  return 'https://$netloc$path${q.isEmpty ? '' : '?$q'}';
}

int _parsePort(String text, String url) {
  if (!RegExp(r'^\d+$').hasMatch(text)) throw InvalidUrl('invalid port: $url');
  final port = int.parse(text);
  if (port > 65535) throw InvalidUrl('invalid port: $url');
  return port;
}

List<(String, String)> _parseQuery(String query) {
  final out = <(String, String)>[];
  for (final piece in query.split('&')) {
    if (piece.isEmpty) continue;
    final eq = piece.indexOf('=');
    final key = eq < 0 ? piece : piece.substring(0, eq);
    final value = eq < 0 ? '' : piece.substring(eq + 1);
    out.add((_unquotePlus(key), _unquotePlus(value)));
  }
  return out;
}

String _unquotePlus(String s) {
  final runes = s.replaceAll('+', ' ').runes.toList();
  final bytes = <int>[];
  var i = 0;
  while (i < runes.length) {
    final c = runes[i];
    if (c == 0x25 && i + 2 < runes.length && _isHex(runes[i + 1]) && _isHex(runes[i + 2])) {
      bytes.add(int.parse(String.fromCharCodes([runes[i + 1], runes[i + 2]]), radix: 16));
      i += 3;
    } else {
      bytes.addAll(utf8.encode(String.fromCharCode(c)));
      i++;
    }
  }
  return utf8.decode(bytes, allowMalformed: true);
}

bool _isHex(int c) =>
    (c >= 0x30 && c <= 0x39) || (c >= 0x41 && c <= 0x46) || (c >= 0x61 && c <= 0x66);

final _unreserved = RegExp(r'[A-Za-z0-9_.\-~]');

/// Python's `urllib.parse.quote_plus` with safe="".
String _quotePlus(String s) {
  final out = StringBuffer();
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    if (_unreserved.hasMatch(ch)) {
      out.write(ch);
    } else if (rune == 0x20) {
      out.write('+');
    } else {
      for (final byte in utf8.encode(ch)) {
        out.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
  }
  return out.toString();
}

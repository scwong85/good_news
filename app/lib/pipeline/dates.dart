/// Feed date parsing (RFC 822 / RFC 1123 and ISO 8601). Always returns UTC or null.
library;

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12, //
};
const _zones = {
  'gmt': 0, 'ut': 0, 'utc': 0, 'z': 0,
  'est': -300, 'edt': -240, 'cst': -360, 'cdt': -300,
  'mst': -420, 'mdt': -360, 'pst': -480, 'pdt': -420, //
};

final _rfc822 = RegExp(
  r'^(?:[A-Za-z]{3,9},?\s+)?(\d{1,2})\s+([A-Za-z]{3,9})\.?\s+(\d{2,4})\s+'
  r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([A-Za-z]{1,5}|[+-]\d{2}:?\d{2})?$',
);

DateTime? parseFeedDate(String? raw) {
  final text = raw?.trim();
  if (text == null || text.isEmpty) return null;
  return _parseRfc822(text) ?? _parseIso(text);
}

DateTime? _parseRfc822(String text) {
  final m = _rfc822.firstMatch(text);
  if (m == null) return null;
  final month = _months[m.group(2)!.substring(0, 3).toLowerCase()];
  if (month == null) return null;
  var year = int.parse(m.group(3)!);
  if (m.group(3)!.length == 2) year += year < 70 ? 2000 : 1900;
  final day = int.parse(m.group(1)!);
  final hour = int.parse(m.group(4)!);
  final minute = int.parse(m.group(5)!);
  final second = int.tryParse(m.group(6) ?? '0') ?? 0;
  if (day < 1 || day > 31 || hour > 23 || minute > 59 || second > 60) return null;
  final zone = m.group(7);
  var offsetMinutes = 0;
  if (zone != null) {
    if (zone.startsWith('+') || zone.startsWith('-')) {
      final digits = zone.substring(1).replaceAll(':', '');
      final minutes = int.parse(digits.substring(0, 2)) * 60 + int.parse(digits.substring(2));
      offsetMinutes = zone.startsWith('-') ? -minutes : minutes;
    } else {
      offsetMinutes = _zones[zone.toLowerCase()] ?? 0;
    }
  }
  return DateTime.utc(year, month, day, hour, minute, second)
      .subtract(Duration(minutes: offsetMinutes));
}

DateTime? _parseIso(String text) {
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  if (parsed.isUtc) return parsed;
  // No zone information: treat the wall-clock time as UTC.
  return DateTime.utc(parsed.year, parsed.month, parsed.day, parsed.hour, parsed.minute,
      parsed.second, parsed.millisecond);
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _two(int n) => n.toString().padLeft(2, '0');

/// "Today, 14:05", "Yesterday", "Mon" (within a week) or "12 Oct" (and the year when it differs).
String formatStoryDate(DateTime published, DateTime now) {
  final p = published.toLocal();
  final n = now.toLocal();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(p.year, p.month, p.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today, ${_two(p.hour)}:${_two(p.minute)}';
  if (diff == 1) return 'Yesterday';
  if (diff > 1 && diff < 7) return _weekdays[p.weekday - 1];
  final base = '${p.day} ${_months[p.month - 1]}';
  return p.year == n.year ? base : '$base ${p.year}';
}

/// A short, calm "last updated" label: "just now", "12 min ago", "3 h ago", "yesterday".
String formatUpdated(DateTime updated, DateTime now) {
  final d = now.difference(updated);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return d.inDays == 1 ? 'yesterday' : '${d.inDays} days ago';
}

/// "Monday 27 October" for the Today header.
String formatLongDay(DateTime now) {
  const full = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
    'October', 'November', 'December', //
  ];
  final l = now.toLocal();
  return '${full[l.weekday - 1]} ${l.day} ${months[l.month - 1]}';
}

String topicLabel(String topic) => topic.isEmpty ? topic : '${topic[0].toUpperCase()}${topic.substring(1)}';

String storyTypeLabel(String type) => switch (type) {
      'science_health' => 'Science & health',
      'education_opportunity' => 'Education & opportunity',
      'technology_for_good' => 'Technology for good',
      'human_interest' => 'Human interest',
      _ => topicLabel(type),
    };

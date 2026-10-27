import 'dart:convert';

import '../data/db/app_database.dart';
import 'daily_selector.dart';

class Preferences {
  const Preferences({
    this.storiesPerDay = defaultStoriesPerDay,
    this.topics = const {},
    this.regions = const {},
  });

  final int storiesPerDay;
  final Set<String> topics;
  final Set<String> regions;
}

/// Reader preferences stored in the on-device `preferences` table.
class PreferencesRepository {
  PreferencesRepository(this.db);
  final AppDatabase db;

  static const _perDay = 'stories_per_day';
  static const _topics = 'topics';
  static const _regions = 'regions';

  Future<Preferences> load() async {
    final perDay = int.tryParse(await db.getPreference(_perDay) ?? '');
    return Preferences(
      storiesPerDay: clampStoriesPerDay(perDay ?? defaultStoriesPerDay),
      topics: _readSet(await db.getPreference(_topics)),
      regions: _readSet(await db.getPreference(_regions)),
    );
  }

  Future<void> setStoriesPerDay(int n) => db.setPreference(_perDay, '${clampStoriesPerDay(n)}');
  Future<void> setTopics(Set<String> topics) => db.setPreference(_topics, jsonEncode(topics.toList()..sort()));
  Future<void> setRegions(Set<String> regions) => db.setPreference(_regions, jsonEncode(regions.toList()..sort()));

  Set<String> _readSet(String? raw) {
    if (raw == null) return const {};
    try {
      return Set<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return const {};
    }
  }
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/data/db/app_database.dart';
import 'package:good_news/selection/daily_selector.dart';
import 'package:good_news/selection/preferences.dart';

void main() {
  late AppDatabase db;
  late PreferencesRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PreferencesRepository(db);
  });
  tearDown(() => db.close());

  test('defaults', () async {
    final p = await repo.load();
    expect(p.storiesPerDay, defaultStoriesPerDay);
    expect(p.topics, isEmpty);
    expect(p.regions, isEmpty);
  });

  test('stories per day is stored and clamped to 5..10', () async {
    await repo.setStoriesPerDay(8);
    expect((await repo.load()).storiesPerDay, 8);
    await repo.setStoriesPerDay(2);
    expect((await repo.load()).storiesPerDay, 5);
    await repo.setStoriesPerDay(50);
    expect((await repo.load()).storiesPerDay, 10);
  });

  test('a corrupt stored value falls back to the default', () async {
    await db.setPreference('stories_per_day', 'lots');
    await db.setPreference('topics', '{not json');
    final p = await repo.load();
    expect(p.storiesPerDay, defaultStoriesPerDay);
    expect(p.topics, isEmpty);
  });

  test('an out-of-range stored value is clamped on load', () async {
    await db.setPreference('stories_per_day', '99');
    expect((await repo.load()).storiesPerDay, 10);
  });

  test('topics and regions round-trip as sets', () async {
    await repo.setTopics({'health', 'environment'});
    await repo.setRegions({'europe'});
    final p = await repo.load();
    expect(p.topics, {'environment', 'health'});
    expect(p.regions, {'europe'});
  });

  test('setting a preference twice keeps one row', () async {
    await repo.setStoriesPerDay(6);
    await repo.setStoriesPerDay(7);
    expect(await db.getPreference('stories_per_day'), '7');
  });
}

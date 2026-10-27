import 'dart:convert';

import 'package:drift/drift.dart';

/// JSON-encoded list of strings stored in a text column.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) => List<String>.from(jsonDecode(fromDb) as List);

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// Bundled sources plus per-device state (see docs/data-model.md).
@DataClassName('SourceRow')
class Sources extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get homepageUrl => text()();
  TextColumn get rssUrl => text()();
  IntColumn get tier => integer()();
  RealColumn get trustScore => real()();
  TextColumn get language => text()();
  TextColumn get regions => text().map(const StringListConverter())();
  BoolColumn get userEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get etag => text().withDefault(const Constant(''))();
  TextColumn get lastModified => text().withDefault(const Constant(''))();
  DateTimeColumn get lastFetchedAt => dateTime().nullable()();
  TextColumn get lastStatus => text().nullable()();
  IntColumn get consecutiveFailures => integer().withDefault(const Constant(0))();
  DateTimeColumn get backoffUntil => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ArticleRow')
@TableIndex(name: 'articles_route_published', columns: {#route, #publishedAt})
class Articles extends Table {
  /// First 16 hex characters of sha1(canonicalUrl).
  TextColumn get id => text()();
  TextColumn get sourceId => text().references(Sources, #id)();
  TextColumn get canonicalUrl => text().unique()();
  TextColumn get title => text()();
  TextColumn get excerpt => text()();
  DateTimeColumn get publishedAt => dateTime()();
  DateTimeColumn get fetchedAt => dateTime()();
  TextColumn get language => text()();
  TextColumn get regions => text().map(const StringListConverter())();
  TextColumn get topics => text().map(const StringListConverter())();
  // Filled by the classifier in Phase 4; null/empty until then.
  TextColumn get storyTypes =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get evidenceSignals =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  RealColumn get constructiveScore => real().nullable()();
  TextColumn get route => text().nullable()();
  TextColumn get explanation => text().nullable()();
  TextColumn get rulesVersion => text().nullable()();
  TextColumn get clusterId => text().nullable()();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// The stories chosen for a local calendar day. Written once per day, extended (never
/// reordered or shortened) when stories_per_day increases.
@DataClassName('DailyPickRow')
class DailyPicks extends Table {
  /// Local date, `yyyy-MM-dd`.
  TextColumn get day => text()();
  IntColumn get position => integer()();
  TextColumn get articleId => text().references(Articles, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {day, position};
}

/// Articles the reader has already seen (opened or shown as a pick).
@DataClassName('SeenRow')
class Seen extends Table {
  TextColumn get articleId => text().references(Articles, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get seenAt => dateTime()();

  @override
  Set<Column> get primaryKey => {articleId};
}

/// Key-value reader preferences (stories_per_day, topics, regions, ...).
@DataClassName('PreferenceRow')
class PreferenceEntries extends Table {
  @override
  String get tableName => 'preferences';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Saved stories. Deliberately no foreign key to `articles`: the snapshot (title, excerpt, source,
/// link, date) keeps the story readable offline after the article itself has been pruned.
@DataClassName('BookmarkRow')
class Bookmarks extends Table {
  TextColumn get articleId => text()();
  DateTimeColumn get savedAt => dateTime()();

  /// JSON object, see `StorySnapshot`.
  TextColumn get snapshot => text()();

  @override
  Set<Column> get primaryKey => {articleId};
}

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

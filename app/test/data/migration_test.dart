import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/data/db/app_database.dart';

import '../generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('upgrading v1 -> v2 keeps existing data and creates the new tables', () async {
    final schema = await verifier.schemaAt(1);
    // A v1 database as shipped with Phase 3: one source and one article.
    schema.rawDatabase.execute(
      "INSERT INTO sources (id, name, homepage_url, rss_url, tier, trust_score, language, regions, user_enabled, etag, last_modified, consecutive_failures) "
      "VALUES ('a', 'Source A', 'https://a.example.com', 'https://a.example.com/feed/', 1, 0.9, 'en', '[\"global\"]', 1, '', '', 0)",
    );
    schema.rawDatabase.execute(
      "INSERT INTO articles (id, source_id, canonical_url, title, excerpt, published_at, fetched_at, language, regions, topics, story_types, evidence_signals, hidden) "
      "VALUES ('0123456789abcdef', 'a', 'https://a.example.com/1', 'Old story', 'e', 1790000000, 1790000100, 'en', '[]', '[\"environment\"]', '[]', '[]', 0)",
    );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);

    expect(await db.articleCount(), 1);
    expect((await db.latestArticles()).single.title, 'Old story');
    // The new tables are usable.
    await db.appendPicks('2026-10-27', ['0123456789abcdef']);
    expect((await db.picksForDay('2026-10-27')).single.articleId, '0123456789abcdef');
    await db.markSeen(['0123456789abcdef'], DateTime.utc(2026, 10, 27));
    expect(await db.seenIds(), {'0123456789abcdef'});
    await db.setPreference('stories_per_day', '7');
    expect(await db.getPreference('stories_per_day'), '7');
    await db.close();
  });

  test('deleting an article cascades to its picks and seen rows', () async {
    final schema = await verifier.schemaAt(2);
    final db = AppDatabase(schema.newConnection());
    await db.upsertBundledSources([]);
    await db.customStatement(
      "INSERT INTO sources (id, name, homepage_url, rss_url, tier, trust_score, language, regions, user_enabled, etag, last_modified, consecutive_failures) "
      "VALUES ('a', 'A', 'https://a', 'https://a/feed', 1, 0.9, 'en', '[]', 1, '', '', 0)",
    );
    await db.customStatement(
      "INSERT INTO articles (id, source_id, canonical_url, title, excerpt, published_at, fetched_at, language, regions, topics, story_types, evidence_signals, hidden) "
      "VALUES ('x', 'a', 'https://a/1', 't', 'e', 1790000000, 1790000100, 'en', '[]', '[]', '[]', '[]', 0)",
    );
    await db.appendPicks('2026-10-27', ['x']);
    await db.markSeen(['x'], DateTime.utc(2026, 10, 27));
    await db.pruneArticles(DateTime.utc(2100));
    expect(await db.picksForDay('2026-10-27'), isEmpty);
    expect(await db.seenIds(), isEmpty);
    await db.close();
  });
}

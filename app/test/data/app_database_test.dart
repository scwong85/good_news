import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/data/db/app_database.dart';
import 'package:good_news/domain/source.dart' as domain;
import 'package:good_news/pipeline/normalize.dart';

domain.Source src(String id, {String name = 'Name', String rss = 'https://example.com/feed/'}) =>
    domain.Source(
      id: id,
      name: name,
      homepageUrl: 'https://example.com',
      rssUrl: rss,
      tier: 1,
      trustScore: 0.9,
      language: 'en',
      regions: const ['global'],
    );

NormalizedItem item(String url, {String title = 'T', DateTime? at}) => NormalizedItem(
      externalId: url,
      canonicalUrl: url,
      title: title,
      excerpt: 'e',
      publishedAt: at ?? DateTime.utc(2026, 10, 27),
      language: 'en',
      regions: const ['global'],
      topics: const ['environment'],
    );

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('in-memory database opens and round-trips JSON list columns', () async {
    await db.upsertBundledSources([src('a')]);
    expect(await db.insertNewArticles('a', [item('https://example.com/1')], DateTime.utc(2026, 10, 27)), 1);
    final row = (await db.latestArticles()).single;
    expect(row.topics, ['environment']);
    expect(row.regions, ['global']);
    expect(row.storyTypes, isEmpty);
    expect(row.hidden, isFalse);
    expect(row.id, articleIdFor('https://example.com/1'));
    expect(row.id, hasLength(16));
  });

  test('insertNewArticles is idempotent and dedupes within a batch', () async {
    await db.upsertBundledSources([src('a')]);
    final at = DateTime.utc(2026, 10, 27);
    final items = [item('https://example.com/1'), item('https://example.com/2'), item('https://example.com/1')];
    expect(await db.insertNewArticles('a', items, at), 2);
    expect(await db.insertNewArticles('a', items, at), 0);
    expect(await db.articleCount(), 2);
  });

  test('upsertBundledSources keeps user state and disables removed sources', () async {
    await db.upsertBundledSources([src('a', name: 'Old'), src('b', rss: 'https://example.com/b/')]);
    await db.setSourceEnabled('a', false);
    await db.recordFetchSuccess('a', at: DateTime.utc(2026, 10, 27), etag: 'e1', lastModified: 'lm', status: 'ok');
    await db.upsertBundledSources([src('a', name: 'New')]);
    final all = {for (final s in await db.allSources()) s.id: s};
    expect(all['a']!.name, 'New');
    expect(all['a']!.userEnabled, isFalse); // user choice kept
    expect(all['a']!.etag, 'e1'); // fetch state kept
    expect(all['b']!.userEnabled, isFalse); // no longer bundled -> disabled
  });

  test('enabledSources only returns enabled ones', () async {
    await db.upsertBundledSources([src('a'), src('b', rss: 'https://example.com/b/')]);
    await db.setSourceEnabled('b', false);
    expect((await db.enabledSources()).map((s) => s.id), ['a']);
  });

  test('failure and success bookkeeping', () async {
    await db.upsertBundledSources([src('a')]);
    await db.recordFetchFailure('a', status: 'error: x', failures: 3, backoffUntil: DateTime.utc(2026, 10, 28));
    var row = (await db.allSources()).single;
    expect((row.consecutiveFailures, row.lastStatus), (3, 'error: x'));
    expect(row.backoffUntil, isNotNull);
    await db.recordFetchSuccess('a', at: DateTime.utc(2026, 10, 27), etag: '', lastModified: '', status: 'ok');
    row = (await db.allSources()).single;
    expect((row.consecutiveFailures, row.backoffUntil), (0, null));
  });

  test('pruneArticles removes only older articles', () async {
    await db.upsertBundledSources([src('a')]);
    await db.insertNewArticles('a', [
      item('https://example.com/old', at: DateTime.utc(2026, 8, 1)),
      item('https://example.com/new', at: DateTime.utc(2026, 10, 27)),
    ], DateTime.utc(2026, 10, 27));
    expect(await db.pruneArticles(DateTime.utc(2026, 9, 27)), 1);
    expect((await db.latestArticles()).single.canonicalUrl, 'https://example.com/new');
  });
}

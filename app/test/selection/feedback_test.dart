import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/data/db/app_database.dart';
import 'package:good_news/selection/daily_picks_service.dart';
import 'package:good_news/selection/feedback_penalty.dart';
import 'package:good_news/selection/feedback_service.dart';
import 'package:good_news/selection/preferences.dart';

import '../ingestion/test_support.dart';

void main() {
  group('sourcePenaltiesFromFeedback', () {
    test('empty feedback means no penalty', () {
      expect(sourcePenaltiesFromFeedback({}), isEmpty);
    });
    test('not credible weighs more than too trivial; other reasons are free', () {
      final p = sourcePenaltiesFromFeedback({
        'a': {notCredibleSignal: 1},
        'b': {tooTrivialSignal: 1},
        'c': {notForMeSignal: 5, alreadySeenSignal: 5},
      });
      expect(p['a'], closeTo(0.10, 1e-9));
      expect(p['b'], closeTo(0.03, 1e-9));
      expect(p.containsKey('c') ? p['c'] : 0, 0);
    });
    test('the penalty is capped', () {
      final p = sourcePenaltiesFromFeedback({
        'a': {notCredibleSignal: 50},
      });
      expect(p['a'], maxSourcePenalty);
    });
  });

  group('hiding', () {
    late AppDatabase db;
    late FakeClock clock;
    late DailyPicksService picks;
    late FeedbackService feedback;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      clock = FakeClock(DateTime.utc(2026, 10, 27, 12));
      picks = DailyPicksService(db, PreferencesRepository(db), now: clock.call);
      feedback = FeedbackService(db, now: clock.call);
      await db.upsertBundledSources(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'].map(source).toList());
      for (var i = 0; i < 12; i++) {
        await addArticle(
          db,
          String.fromCharCode('a'.codeUnitAt(0) + (i % 8)),
          slug: 's$i',
          route: 'today',
          score: 0.8 - i * 0.01,
          topics: ['topics$i'],
          publishedAt: clock.value.subtract(const Duration(hours: 3)),
        );
      }
    });
    tearDown(() => db.close());

    test('a hidden pick leaves the day and its slot is refilled', () async {
      final first = await picks.todaysPicks();
      expect(first, hasLength(5));
      final gone = first[1];
      await feedback.hide(articleId: gone.id, sourceId: gone.sourceId, reason: HideReason.notForMe);
      final after = await picks.todaysPicks();
      expect(after, hasLength(5));
      expect(after.map((a) => a.id), isNot(contains(gone.id)));
      expect(after.map((a) => a.id).where(first.map((a) => a.id).contains), hasLength(4));
    });

    test('a hidden story never comes back, even on a later day', () async {
      final first = await picks.todaysPicks();
      final gone = first.first;
      await feedback.hide(articleId: gone.id, sourceId: gone.sourceId, reason: HideReason.tooTrivial);
      clock.advance(const Duration(hours: 26));
      expect((await picks.todaysPicks()).map((a) => a.id), isNot(contains(gone.id)));
    });

    test('hiding records the reason and lists the story', () async {
      final a = (await picks.todaysPicks()).first;
      await feedback.hide(articleId: a.id, sourceId: a.sourceId, reason: HideReason.notCredible);
      expect(await db.feedbackCountsBySource(), {
        a.sourceId: {notCredibleSignal: 1},
      });
      expect((await db.hiddenArticles()).map((r) => r.$1.id), [a.id]);
    });

    test('restoring brings the story back and clears its feedback', () async {
      final a = (await picks.todaysPicks()).first;
      await feedback.hide(articleId: a.id, sourceId: a.sourceId, reason: HideReason.notCredible);
      await feedback.restore(a.id);
      expect(await db.hiddenArticles(), isEmpty);
      expect(await db.feedbackCountsBySource(), isEmpty);
    });

    test('feedback survives pruning of the article', () async {
      final a = (await picks.todaysPicks()).first;
      await feedback.hide(articleId: a.id, sourceId: a.sourceId, reason: HideReason.notCredible);
      await db.pruneArticles(DateTime.utc(2100));
      expect((await db.feedbackCountsBySource())[a.sourceId], {notCredibleSignal: 1});
    });
  });
}

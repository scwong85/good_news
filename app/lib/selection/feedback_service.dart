import '../data/db/app_database.dart';
import 'feedback_penalty.dart';

/// Why a reader hid a story. Local only.
enum HideReason {
  notForMe(notForMeSignal, 'Not for me', 'Just not my kind of story.'),
  tooTrivial(tooTrivialSignal, 'Too trivial', 'Not meaningful enough to be in the news.'),
  notCredible(notCredibleSignal, 'Not credible', "I don't trust this story or its source."),
  alreadySeen(alreadySeenSignal, 'Already seen', 'I have already seen this news.');

  const HideReason(this.signal, this.label, this.description);
  final String signal;
  final String label;
  final String description;
}

/// Hiding and restoring stories (`after_feedback` hook, docs/pipeline-hooks.md). Everything
/// stays on this phone: a hidden story is never picked or listed again, its slot in today's picks
/// is refilled, and "not credible" / "too trivial" reports lower the source's rank.
class FeedbackService {
  FeedbackService(this.db, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _now;

  Future<void> hide({required String articleId, required String sourceId, required HideReason reason}) async {
    await db.transaction(() async {
      await db.recordFeedback(articleId, sourceId, reason.signal, _now().toUtc());
      await db.setHidden(articleId, true);
      await db.removePicksOf(articleId);
    });
  }

  /// Brings a hidden story back (it may be picked again) and forgets the reports about it.
  Future<void> restore(String articleId) async {
    await db.transaction(() async {
      await db.setHidden(articleId, false);
      await db.deleteFeedbackFor(articleId);
    });
  }
}

/// Abstract interface only — see `academic_record_repository.dart` for the
/// purity rationale. Unlike every other repository in this directory, the
/// concrete implementation has no local-first fallback: a feedback feed
/// shared across every student is, by definition, not a single device's
/// data to own offline. See `SupabaseFeedbackRepository`'s doc comment.
library;

import '../models/app_feedback.dart';

class FeedbackRateLimitedException implements Exception {
  const FeedbackRateLimitedException();
}

abstract class FeedbackRepository {
  /// Newest first. Throws on a genuine network/server failure -- callers
  /// show an honest offline/error state rather than a silently empty feed.
  Future<List<AppFeedback>> loadFeed();

  /// Throws [FeedbackRateLimitedException] if this account already
  /// submitted within the last 24 hours (enforced server-side by a
  /// Postgres trigger, not just client-side UI state, so it holds even if
  /// local state is cleared or a different device is used).
  Future<void> submit({
    required int rating,
    required String comment,
    required String? displayName,
  });
}

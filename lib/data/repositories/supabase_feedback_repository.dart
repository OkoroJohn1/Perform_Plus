/// The one deliberate exception to this app's offline-first rule (see
/// AGENTS.md's "Offline-first is non-negotiable"): a feedback feed that
/// shows every student's entries, not just this device's own data, cannot
/// be meaningfully local-first -- there is nothing to show offline that
/// wasn't already fetched, and a submission genuinely has to reach the
/// shared `app_feedback` table to mean anything. `FeedbackScreen` shows an
/// honest "you're offline" state rather than pretending otherwise, the same
/// way the AI advisor already does for its own always-online feature.
///
/// The 24-hour submission limit is enforced twice, deliberately: client-side
/// (`FeedbackController` hides the submit form once a day) for the normal
/// UX, and server-side (a Postgres trigger on `app_feedback`, see the
/// `app_feedback_table` migration) as the real enforcement, since client
/// state can be cleared or bypassed from a different device. This mirrors
/// the same two-layer discipline already used for `extract-course-slip`'s
/// 20/24h cap and `ai-advisor`'s 50/24h cap.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/app_feedback.dart';
import '../../domain/repositories/feedback_repository.dart';

class SupabaseFeedbackRepository implements FeedbackRepository {
  final SupabaseClient _client;

  SupabaseFeedbackRepository(this._client);

  @override
  Future<List<AppFeedback>> loadFeed() async {
    final rows = await _client
        .from('app_feedback')
        .select('id, display_name, rating, comment, created_at')
        .order('created_at', ascending: false)
        .limit(200);

    return (rows as List).map((row) {
      final map = row as Map<String, dynamic>;
      return AppFeedback(
        id: map['id'] as String,
        displayName: map['display_name'] as String?,
        rating: map['rating'] as int,
        comment: map['comment'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }).toList();
  }

  @override
  Future<void> submit({
    required int rating,
    required String comment,
    required String? displayName,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Cannot submit feedback while signed out.');
    }
    try {
      await _client.from('app_feedback').insert({
        'user_id': uid,
        'display_name': displayName,
        'rating': rating,
        'comment': comment,
      });
    } on PostgrestException catch (e) {
      // The rate-limit trigger raises a plain Postgres exception with this
      // exact message (see the `app_feedback_table` migration) -- there is
      // no structured error code to switch on for a raised `plpgsql`
      // exception, so matching the message text is the only seam available.
      if (e.message.contains('once every 24 hours')) {
        throw const FeedbackRateLimitedException();
      }
      rethrow;
    }
  }
}

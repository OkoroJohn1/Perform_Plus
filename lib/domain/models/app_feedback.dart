/// A single feedback entry on the shared, cross-user feedback feed (the
/// "Feedback" tab). Unlike every other model in `domain/models/`, this one
/// has no local-first story of its own -- the feed is inherently a shared,
/// always-online concept (everyone's feedback, not just this device's), so
/// there is no Drift table backing it; it is read and written straight
/// through `FeedbackRepository`'s Supabase implementation. See that
/// repository's doc comment for why this is the one deliberate exception to
/// this app's offline-first rule.
library;

class AppFeedback {
  final String id;

  /// Null when submitted anonymously (the default) -- never assume this is
  /// present when rendering a feed row.
  final String? displayName;

  /// 1-5. Each value has a fixed, displayed meaning -- see
  /// `StarRating.labelFor` in `feedback_screen.dart`; never shown as a bare
  /// number with no meaning attached.
  final int rating;

  final String comment;
  final DateTime createdAt;

  const AppFeedback({
    required this.id,
    required this.displayName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  bool get isAnonymous => displayName == null || displayName!.trim().isEmpty;
}

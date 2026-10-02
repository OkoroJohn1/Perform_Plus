/// Notification domain model and content generation. Pure Dart — no
/// Flutter, no Drift, no I/O.
///
/// Every type here has a real trigger in existing app code (see each
/// function's doc comment for what fires it) — nothing is stubbed, and
/// nothing invents a metric the app doesn't have. Icon/colour are a
/// presentation concern and live in `notifications_panel.dart`.
library;

import 'course_result.dart';
import 'grading_scheme.dart';

enum AppNotificationType {
  resultAdded,
  cgpaChanged,
  goalPaceChanged,
  achievementUnlocked,
  studyReminder,
  streakAtRisk,
  carryoverFlagged,
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;

  /// Free-form string metadata used for routing on tap (e.g. a semester id)
  /// and for presentation details that don't warrant their own column
  /// (e.g. `cgpaChanged`'s "rising" flag) — see `notifications_panel.dart`.
  final Map<String, String> payload;

  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.payload = const {},
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        payload: payload,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
      );
}

String _fmt(double v) => v.toStringAsFixed(2);

/// "{level}L {term label}" — term naming always read from the scheme (e.g.
/// FUTO's Harmattan/Rain), never a generic "1st/2nd/3rd Semester".
String semesterPhrase(GradingScheme scheme, int level, SemesterTerm term) =>
    '${level}L ${scheme.termLabel(term)}';

/// Fires after a semester commits.
({String title, String body}) resultAddedContent({
  required GradingScheme scheme,
  required int level,
  required SemesterTerm term,
  required double cgpa,
}) =>
    (
      title: 'Semester result added',
      body: 'Your ${semesterPhrase(scheme, level, term)} results are saved. '
          'CGPA is now ${_fmt(cgpa)}.',
    );

/// Fires alongside [resultAddedContent], from the same
/// `RecalculationResult`. Rising and falling are both real outcomes of
/// adding a result — falling must read as a neutral statement of what
/// happened, never a congratulation misapplied, and never scolding either.
({String title, String body, bool rising}) cgpaChangedContent({
  required GradingScheme scheme,
  required int level,
  required SemesterTerm term,
  required double delta,
  required double cgpa,
}) {
  final phrase = semesterPhrase(scheme, level, term);
  if (delta >= 0) {
    return (
      title: 'Your CGPA went up',
      body: 'Up ${_fmt(delta)} to ${_fmt(cgpa)} after adding $phrase.',
      rising: true,
    );
  }
  return (
    title: 'Your CGPA changed',
    body: 'Down ${_fmt(delta.abs())} to ${_fmt(cgpa)} after adding $phrase.',
    rising: false,
  );
}

/// Fires when a goal's feasibility category changes. Callers should only
/// invoke this when a solved `requiredAverage` actually exists — see
/// `TargetProjection.requiredAverage`'s own null case (e.g. no credits
/// left) — rather than fabricate a number for the body.
({String title, String body}) goalPaceChangedContent({
  required double requiredAverage,
  required String bandLabel,
  required int semestersRemaining,
}) =>
    (
      title: 'Your goal needs ${_fmt(requiredAverage)} now',
      body: 'After your latest results, $bandLabel needs ${_fmt(requiredAverage)} '
          'per semester across $semestersRemaining remaining.',
    );

/// Fires when `AchievementsController.evaluate` unlocks a new badge.
({String title, String body}) achievementUnlockedContent({
  required String badgeName,
  required String criteria,
}) =>
    (title: 'Achievement unlocked', body: 'You earned $badgeName — $criteria.');

/// A local scheduled notification from the Study tab's daily plan.
({String title, String body}) studyReminderContent({
  required int pages,
  required String noteTitle,
}) =>
    (
      title: 'Time to read',
      body: '$pages page${pages == 1 ? '' : 's'} planned for today in $noteTitle.',
    );

/// Fires at 8pm local when the day has no logged reading and a streak is
/// active.
({String title, String body}) streakAtRiskContent({required int streak}) => (
      title: 'Your $streak-day streak ends tonight',
      body: 'Read for 10 minutes to keep it.',
    );

/// Fires when a semester commit introduces a new carryover (a repeat
/// attempt, or a first attempt that's still failing).
({String title, String body}) carryoverFlaggedContent({
  required String courseCode,
  required String institutionName,
  required String policyDescription,
}) =>
    (
      title: '$courseCode is a carryover',
      body: "Under $institutionName's rules, $policyDescription.",
    );

/// Retention: 90 days, pruned on app start — an unbounded list on a
/// storage-limited device is not acceptable.
const notificationRetention = Duration(days: 90);

List<AppNotification> pruneOlderThan(
  List<AppNotification> notifications,
  DateTime now, {
  Duration retention = notificationRetention,
}) {
  final cutoff = now.subtract(retention);
  return notifications.where((n) => n.createdAt.isAfter(cutoff)).toList();
}

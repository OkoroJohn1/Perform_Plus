/// Achievement trigger evaluation — pure Dart, no Flutter, no I/O.
/// Every trigger reads only [AcademicStanding]/[SemesterComputation] (the
/// engine's own output) or a reading streak already computed by
/// `study_engine.dart`; nothing here invents a metric.
library;

import 'cgpa_engine.dart';
import '../models/achievement.dart';

/// The full set of badges [standing]/[currentStreak] currently qualify
/// for — a snapshot, not a diff. Callers (see `achievement_provider.dart`)
/// compare this against what's already unlocked to find newly-earned ones;
/// nothing is ever revoked once unlocked, even if the underlying condition
/// later stops holding (e.g. the streak resets) — an achievement records
/// something that happened, not a live status.
Set<BadgeId> evaluateEarnedBadges({
  required AcademicStanding standing,
  required int currentStreak,
}) {
  final earned = <BadgeId>{};

  if (standing.hasData) earned.add(BadgeId.firstSteps);
  if (currentStreak >= 7) earned.add(BadgeId.consistentLearner);

  final withData = standing.semesters.where((s) => s.creditUnits > 0).toList();
  if (withData.any((s) => s.gpa > 4.0)) earned.add(BadgeId.topPerformer);

  for (var i = 1; i < withData.length; i++) {
    if (withData[i].gpa - withData[i - 1].gpa >= 0.5) {
      earned.add(BadgeId.improvementKing);
      break;
    }
  }

  return earned;
}

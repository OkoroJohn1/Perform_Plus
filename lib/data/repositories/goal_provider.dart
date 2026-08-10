/// Student's goal target.
///
/// TODO(v1): wire to the goal-setting screen (currently a stub, see
/// goal_setting_screen.dart) and persist alongside the profile. Nothing
/// sets this yet, so the goal ring shows a "set a goal" prompt for every
/// user today — the honest state, not a fabricated one.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/engine/projection_solver.dart';
import '../../domain/models/grading_scheme.dart';
import 'academic_record_provider.dart';

class GoalTarget {
  final ClassificationBand band;
  final int semestersRemaining;

  const GoalTarget({required this.band, required this.semestersRemaining});
}

final goalProvider = StateProvider<GoalTarget?>((ref) => null);

/// Null when no goal is set or the record has no data yet — the ring has
/// nothing honest to show in either case.
final targetProjectionProvider = Provider<TargetProjection?>((ref) {
  final goal = ref.watch(goalProvider);
  if (goal == null) return null;

  final standing = ref.watch(standingProvider);
  if (!standing.hasData) return null;

  final record = ref.watch(academicRecordProvider);
  return ProjectionSolver.solveForTarget(
    standing: standing,
    scheme: record.scheme,
    targetCgpa: goal.band.minCgpa,
    targetLabel: goal.band.label,
    semestersRemaining: goal.semestersRemaining,
  );
});

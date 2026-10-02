/// Student's goal target — persisted via [GoalRepository] so it survives
/// restarts. Nothing sets this until the student saves a goal, so the ring
/// shows a "set a goal" prompt for every user until then — the honest
/// state, not a fabricated one.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/engine/projection_solver.dart';
import '../../domain/models/goal_target.dart';
import '../../domain/repositories/goal_repository.dart';
import 'academic_record_provider.dart';
import 'repository_providers.dart';

export '../../domain/models/goal_target.dart';

class GoalController extends StateNotifier<GoalTarget?> {
  final GoalRepository _repository;

  GoalController(this._repository) : super(null) {
    unawaited(_loadPersisted());
  }

  Future<void> _loadPersisted() async {
    final persisted = await _repository.loadGoal();
    if (persisted != null) state = persisted;
  }

  /// Awaits the local Drift write (so a caller can show a genuine loading
  /// state and time it out) rather than firing it and forgetting. There is
  /// no remote `goals` table in the current Supabase schema to sync to —
  /// unlike the profile screen's `ProfileRemoteSync`, this deliberately
  /// does not invent one. Add a remote mirror here once that table exists.
  Future<void> save(GoalTarget goal) async {
    state = goal;
    await _repository.saveGoal(goal);
  }

  void clear() {
    state = null;
    unawaited(_repository.clearGoal());
  }
}

final goalProvider = StateNotifierProvider<GoalController, GoalTarget?>(
  (ref) => GoalController(ref.watch(goalRepositoryProvider)),
);

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

/// Drift-backed [GoalRepository]. `GoalTarget.band` is flattened into flat
/// columns (see `goals_table.dart`) rather than JSON-encoded.
library;

import '../../core/constants/app_constants.dart';
import '../../domain/models/goal_target.dart';
import '../../domain/models/grading_scheme.dart';
import '../../domain/repositories/goal_repository.dart';
import '../local/app_database.dart';
import '../local/daos/goal_dao.dart';

class DriftGoalRepository implements GoalRepository {
  final GoalDao _dao;

  DriftGoalRepository(this._dao);

  @override
  Future<GoalTarget?> loadGoal() async {
    final row = await _dao.getGoal(AppConstants.localProfileId);
    if (row == null) return null;
    return GoalTarget(
      band: ClassificationBand(
        label: row.bandLabel,
        shortLabel: row.bandShortLabel,
        minCgpa: row.bandMinCgpa,
        maxCgpa: row.bandMaxCgpa,
      ),
      semestersRemaining: row.semestersRemaining,
    );
  }

  @override
  Future<void> saveGoal(GoalTarget goal) => _dao.upsertGoal(
        GoalsCompanion.insert(
          profileId: AppConstants.localProfileId,
          bandLabel: goal.band.label,
          bandShortLabel: goal.band.shortLabel,
          bandMinCgpa: goal.band.minCgpa,
          bandMaxCgpa: goal.band.maxCgpa,
          semestersRemaining: goal.semestersRemaining,
          updatedAt: DateTime.now(),
        ),
      );

  @override
  Future<void> clearGoal() => _dao.deleteGoal(AppConstants.localProfileId);
}

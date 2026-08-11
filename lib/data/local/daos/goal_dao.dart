import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/goals_table.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [Goals])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  Future<Goal?> getGoal(String profileId) =>
      (select(goals)..where((g) => g.profileId.equals(profileId))).getSingleOrNull();

  Future<void> upsertGoal(GoalsCompanion entry) =>
      into(goals).insertOnConflictUpdate(entry);

  Future<void> deleteGoal(String profileId) =>
      (delete(goals)..where((g) => g.profileId.equals(profileId))).go();
}

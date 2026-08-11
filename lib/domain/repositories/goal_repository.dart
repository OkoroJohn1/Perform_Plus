/// Abstract interface only — see `academic_record_repository.dart` for the
/// purity rationale.
library;

import '../models/goal_target.dart';

abstract class GoalRepository {
  Future<GoalTarget?> loadGoal();
  Future<void> saveGoal(GoalTarget goal);
  Future<void> clearGoal();
}

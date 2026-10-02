import 'package:drift/drift.dart';

import '../../../domain/models/achievement.dart';

/// One row per badge the student has ever earned. Never deleted or
/// re-evaluated away — see `achievement_engine.dart`'s doc comment on why
/// unlocking is one-directional.
@DataClassName('AchievementRow')
class Achievements extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get badgeId => textEnum<BadgeId>()();
  DateTimeColumn get unlockedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

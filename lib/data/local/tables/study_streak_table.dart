import 'package:drift/drift.dart';

/// Singleton row (same pattern as `Goals`), holding the ONLY two fields the
/// reading streak is allowed to be computed from — see
/// `study_engine.dart`'s `effectiveStreak`/`recordQualifyingRead`: the
/// streak must never be re-derived by scanning `ReadingSessions` history at
/// read time, so it has to be stored somewhere, and this is that somewhere.
/// (Not one of the three tables the task named explicitly — added because
/// "store lastReadDate and currentStreak" has nowhere else honest to live.)
@DataClassName('StudyStreakRow')
class StudyStreaks extends Table {
  TextColumn get profileId => text()();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReadDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {profileId};
}

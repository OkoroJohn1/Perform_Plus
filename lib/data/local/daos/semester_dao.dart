import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/semesters_table.dart';

part 'semester_dao.g.dart';

@DriftAccessor(tables: [Semesters])
class SemesterDao extends DatabaseAccessor<AppDatabase> with _$SemesterDaoMixin {
  SemesterDao(super.db);

  Future<List<SemesterRow>> getSemestersForProfile(String profileId) =>
      (select(semesters)..where((s) => s.profileId.equals(profileId))).get();

  /// Every semester in the local DB, regardless of `profileId` — the local
  /// DB only ever holds one profile's worth of data (see `profiles_table.dart`'s
  /// "Singleton row" doc comment), so this is what the rest of the app
  /// should actually read from; filtering by profile id here would make a
  /// semester invisible the moment `reassignProfile` moves it off whatever
  /// constant the caller still expects.
  Future<List<SemesterRow>> getAllSemesters() => select(semesters).get();

  Future<void> upsertSemester(SemestersCompanion entry) =>
      into(semesters).insertOnConflictUpdate(entry);

  Future<void> deleteSemester(String id) =>
      (delete(semesters)..where((s) => s.id.equals(id))).go();

  Future<int> reassignProfile(String fromProfileId, String toProfileId) =>
      (update(semesters)..where((s) => s.profileId.equals(fromProfileId)))
          .write(SemestersCompanion(profileId: Value(toProfileId)));

  Future<void> deleteAllForProfile(String profileId) =>
      (delete(semesters)..where((s) => s.profileId.equals(profileId))).go();
}

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/semesters_table.dart';

part 'semester_dao.g.dart';

@DriftAccessor(tables: [Semesters])
class SemesterDao extends DatabaseAccessor<AppDatabase> with _$SemesterDaoMixin {
  SemesterDao(super.db);

  Future<List<SemesterRow>> getSemestersForProfile(String profileId) =>
      (select(semesters)..where((s) => s.profileId.equals(profileId))).get();

  Future<void> upsertSemester(SemestersCompanion entry) =>
      into(semesters).insertOnConflictUpdate(entry);

  Future<void> deleteSemester(String id) =>
      (delete(semesters)..where((s) => s.id.equals(id))).go();
}

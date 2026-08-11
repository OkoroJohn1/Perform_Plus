import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/course_results_table.dart';

part 'course_result_dao.g.dart';

@DriftAccessor(tables: [CourseResults])
class CourseResultDao extends DatabaseAccessor<AppDatabase>
    with _$CourseResultDaoMixin {
  CourseResultDao(super.db);

  /// Batch-loads results for many semesters at once — avoids an N+1 query
  /// when the repository reconstructs a whole academic record.
  Future<List<CourseResultRow>> getResultsForSemesters(List<String> semesterIds) =>
      (select(courseResults)..where((r) => r.semesterId.isIn(semesterIds))).get();

  Future<void> upsertResults(List<CourseResultsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(courseResults, rows));

  Future<void> deleteResultsForSemester(String semesterId) =>
      (delete(courseResults)..where((r) => r.semesterId.equals(semesterId))).go();
}

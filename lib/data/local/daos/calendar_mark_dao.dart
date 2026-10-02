import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/calendar_marks_table.dart';

part 'calendar_mark_dao.g.dart';

@DriftAccessor(tables: [CalendarMarks])
class CalendarMarkDao extends DatabaseAccessor<AppDatabase> with _$CalendarMarkDaoMixin {
  CalendarMarkDao(super.db);

  /// Every mark, regardless of `profileId` — the local DB only ever holds
  /// one profile's worth of data (same convention as `SemesterDao.getAllSemesters`).
  Future<List<CalendarMarkRow>> getAllMarks() => select(calendarMarks).get();

  Future<void> upsertMark(CalendarMarksCompanion entry) =>
      into(calendarMarks).insertOnConflictUpdate(entry);

  Future<void> deleteMark(String id) => (delete(calendarMarks)..where((m) => m.id.equals(id))).go();

  Future<void> deleteAllForProfile(String profileId) =>
      (delete(calendarMarks)..where((m) => m.profileId.equals(profileId))).go();
}

import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/calendar_mark.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../local/app_database.dart';
import '../local/daos/calendar_mark_dao.dart';

class DriftCalendarRepository implements CalendarRepository {
  final CalendarMarkDao _dao;

  DriftCalendarRepository(this._dao);

  @override
  Future<List<CalendarMark>> loadMarks() async {
    final rows = await _dao.getAllMarks();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> setMark({required String id, required DateTime date, String? note}) async {
    final now = DateTime.now();
    await _dao.upsertMark(
      CalendarMarksCompanion.insert(
        id: id,
        profileId: AppConstants.localProfileId,
        date: normalizeDate(date),
        note: Value(note),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> removeMark(String id) => _dao.deleteMark(id);

  CalendarMark _toDomain(CalendarMarkRow row) => CalendarMark(
        id: row.id,
        profileId: row.profileId,
        date: row.date,
        note: row.note,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}

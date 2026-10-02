/// Abstract interface only — see `academic_record_repository.dart`'s doc
/// comment for why (`lib/domain/` stays pure, no Flutter/Drift imports).
library;

import '../models/calendar_mark.dart';

abstract class CalendarRepository {
  Future<List<CalendarMark>> loadMarks();

  /// Creates or replaces the mark for [date] (already normalized by the
  /// caller). A no-op-safe upsert: marking an already-marked date again
  /// just updates its note.
  Future<void> setMark({required String id, required DateTime date, String? note});

  Future<void> removeMark(String id);
}

/// A single marked day on the Study tab's calendar — pure Dart, no Flutter/
/// Drift imports. One mark per calendar date per profile; marking an
/// already-marked date again just replaces its note.
library;

class CalendarMark {
  final String id;
  final String profileId;

  /// Normalized to local midnight — callers must strip the time component
  /// before constructing one of these, since equality/lookup is by date
  /// only (see `normalizeDate`).
  final DateTime date;

  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalendarMark({
    required this.id,
    required this.profileId,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Strips the time-of-day component so a mark always keys off the calendar
/// date alone, regardless of what time it was tapped.
DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

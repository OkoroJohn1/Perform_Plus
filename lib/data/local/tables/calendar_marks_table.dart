import 'package:drift/drift.dart';

/// One row per marked calendar date on the Study tab. `date` is always
/// stored normalized to local midnight (see `normalizeDate` in the domain
/// model) so a lookup by date never has to fuzzy-match a time component.
///
/// `@DataClassName('CalendarMarkRow')` avoids colliding with the domain
/// model `CalendarMark` -- same convention as `SemesterRow`/`CourseResultRow`
/// elsewhere in this table layer.
@DataClassName('CalendarMarkRow')
class CalendarMarks extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

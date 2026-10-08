import 'package:drift/drift.dart';

/// One row per slip photo kept in the Result slip wallet (Results screen).
/// `@DataClassName('SlipUploadRow')` avoids colliding with the domain model
/// `SlipUpload` -- same convention as `CalendarMarkRow`/`SemesterRow`
/// elsewhere in this table layer.
@DataClassName('SlipUploadRow')
class SlipUploads extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();

  /// Stored as text (`SlipKind.name`) rather than an int index -- same
  /// reasoning as `NoteCategory`'s `textEnum` elsewhere: a reordered enum
  /// can never silently relabel an old row.
  TextColumn get kind => text()();

  TextColumn get filePath => text()();
  IntColumn get extractedCourseCount => integer().nullable()();
  DateTimeColumn get capturedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

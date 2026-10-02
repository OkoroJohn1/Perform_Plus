import 'package:drift/drift.dart';

import '../../../domain/models/note.dart';

/// `courseCode`/`examYear` only apply to `NoteCategory.pastQuestion` rows —
/// see `note.dart`'s doc comment on why past questions share this table
/// rather than getting their own.
@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get title => text()();
  TextColumn get filePath => text()();
  TextColumn get fileType => textEnum<NoteFileType>()();
  IntColumn get totalPages => integer()();
  IntColumn get colourIndex => integer()();
  DateTimeColumn get uploadedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  TextColumn get category => textEnum<NoteCategory>().withDefault(const Constant('note'))();
  TextColumn get courseCode => text().nullable()();
  IntColumn get examYear => integer().nullable()();
  TextColumn get storagePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

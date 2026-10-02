import 'package:drift/drift.dart';

/// One row per page of a note, created up front when the note is uploaded
/// (so progress can be queried as a simple count) — composite-keyed by
/// (noteId, pageIndex) rather than a synthetic id, since a page is exactly
/// identified by its position within its note.
@DataClassName('NotePageRow')
class NotePages extends Table {
  TextColumn get noteId => text()();
  IntColumn get pageIndex => integer()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get readAt => dateTime().nullable()();
  IntColumn get dwellSeconds => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {noteId, pageIndex};
}

import 'package:drift/drift.dart';

/// One row per reader session. Study hours and the day streak derive from
/// [activeSeconds] here — never from wall-clock `endedAt - startedAt`,
/// which would include backgrounded/idle/paused time.
@DataClassName('ReadingSessionRow')
class ReadingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get pagesRead => integer()();
  IntColumn get activeSeconds => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

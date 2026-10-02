// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_dao.dart';

// ignore_for_file: type=lint
mixin _$NoteDaoMixin on DatabaseAccessor<AppDatabase> {
  $NotesTable get notes => attachedDatabase.notes;
  $NotePagesTable get notePages => attachedDatabase.notePages;
  $ReadingSessionsTable get readingSessions => attachedDatabase.readingSessions;
  $StudyStreaksTable get studyStreaks => attachedDatabase.studyStreaks;
  NoteDaoManager get managers => NoteDaoManager(this);
}

class NoteDaoManager {
  final _$NoteDaoMixin _db;
  NoteDaoManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db.attachedDatabase, _db.notes);
  $$NotePagesTableTableManager get notePages =>
      $$NotePagesTableTableManager(_db.attachedDatabase, _db.notePages);
  $$ReadingSessionsTableTableManager get readingSessions =>
      $$ReadingSessionsTableTableManager(
          _db.attachedDatabase, _db.readingSessions);
  $$StudyStreaksTableTableManager get studyStreaks =>
      $$StudyStreaksTableTableManager(_db.attachedDatabase, _db.studyStreaks);
}

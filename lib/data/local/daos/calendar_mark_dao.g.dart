// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_mark_dao.dart';

// ignore_for_file: type=lint
mixin _$CalendarMarkDaoMixin on DatabaseAccessor<AppDatabase> {
  $CalendarMarksTable get calendarMarks => attachedDatabase.calendarMarks;
  CalendarMarkDaoManager get managers => CalendarMarkDaoManager(this);
}

class CalendarMarkDaoManager {
  final _$CalendarMarkDaoMixin _db;
  CalendarMarkDaoManager(this._db);
  $$CalendarMarksTableTableManager get calendarMarks =>
      $$CalendarMarksTableTableManager(_db.attachedDatabase, _db.calendarMarks);
}

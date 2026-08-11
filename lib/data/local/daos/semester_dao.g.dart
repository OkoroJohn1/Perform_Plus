// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_dao.dart';

// ignore_for_file: type=lint
mixin _$SemesterDaoMixin on DatabaseAccessor<AppDatabase> {
  $SemestersTable get semesters => attachedDatabase.semesters;
  SemesterDaoManager get managers => SemesterDaoManager(this);
}

class SemesterDaoManager {
  final _$SemesterDaoMixin _db;
  SemesterDaoManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db.attachedDatabase, _db.semesters);
}

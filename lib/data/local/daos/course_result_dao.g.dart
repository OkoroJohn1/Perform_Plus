// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_result_dao.dart';

// ignore_for_file: type=lint
mixin _$CourseResultDaoMixin on DatabaseAccessor<AppDatabase> {
  $CourseResultsTable get courseResults => attachedDatabase.courseResults;
  CourseResultDaoManager get managers => CourseResultDaoManager(this);
}

class CourseResultDaoManager {
  final _$CourseResultDaoMixin _db;
  CourseResultDaoManager(this._db);
  $$CourseResultsTableTableManager get courseResults =>
      $$CourseResultsTableTableManager(_db.attachedDatabase, _db.courseResults);
}

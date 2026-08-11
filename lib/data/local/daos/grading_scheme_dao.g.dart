// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grading_scheme_dao.dart';

// ignore_for_file: type=lint
mixin _$GradingSchemeDaoMixin on DatabaseAccessor<AppDatabase> {
  $GradingSchemesTable get gradingSchemes => attachedDatabase.gradingSchemes;
  GradingSchemeDaoManager get managers => GradingSchemeDaoManager(this);
}

class GradingSchemeDaoManager {
  final _$GradingSchemeDaoMixin _db;
  GradingSchemeDaoManager(this._db);
  $$GradingSchemesTableTableManager get gradingSchemes =>
      $$GradingSchemesTableTableManager(
          _db.attachedDatabase, _db.gradingSchemes);
}

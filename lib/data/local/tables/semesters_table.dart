import 'package:drift/drift.dart';

import '../../../domain/models/course_result.dart';

/// Maps 1:1 to the domain `Semester` model, minus `results` — those live
/// in `CourseResults`, joined by `semesterId`.
///
/// `@DataClassName('SemesterRow')` avoids colliding with the domain
/// `Semester` class — Drift's default row class name would otherwise be
/// the singular of the table name, i.e. `Semester` too.
@DataClassName('SemesterRow')
class Semesters extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get session => text()();
  TextColumn get term => textEnum<SemesterTerm>()();
  IntColumn get level => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

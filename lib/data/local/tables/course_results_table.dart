import 'package:drift/drift.dart';

import '../../../domain/models/course_result.dart';

/// Maps 1:1 to the domain `CourseResult` model. `semesterId` links back to
/// `Semesters`.
///
/// `@DataClassName('CourseResultRow')` avoids colliding with the domain
/// `CourseResult` class — see `semesters_table.dart` for the same issue.
@DataClassName('CourseResultRow')
class CourseResults extends Table {
  TextColumn get id => text()();
  TextColumn get semesterId => text()();
  TextColumn get courseCode => text()();
  TextColumn get courseTitle => text().nullable()();
  IntColumn get creditUnit => integer()();
  TextColumn get grade => text()();
  IntColumn get score => integer().nullable()();
  IntColumn get attempt => integer().withDefault(const Constant(1))();
  TextColumn get supersedesResultId => text().nullable()();
  TextColumn get source => textEnum<ResultSource>()();
  RealColumn get extractionConfidence => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

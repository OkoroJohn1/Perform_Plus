import 'package:drift/drift.dart';

import '../../../domain/models/grading_scheme.dart';
import '../converters/classification_band_list_converter.dart';
import '../converters/grade_definition_list_converter.dart';

/// Every scheme a student has ever used gets snapshotted here, keyed by the
/// domain model's own `id` (e.g. `futo_v1`, or a generated uuid for custom
/// schemes) — a real multi-row table, not a singleton. This is what keeps
/// historical semesters "remain computable" even if `defaultSchemes`
/// changes in a later app version (see AGENTS.md's versioning rationale).
///
/// `@DataClassName('GradingSchemeRow')` avoids colliding with the domain
/// `GradingScheme` class — see `semesters_table.dart` for the same issue.
@DataClassName('GradingSchemeRow')
class GradingSchemes extends Table {
  TextColumn get id => text()();
  TextColumn get institutionId => text()();
  TextColumn get name => text()();
  IntColumn get version => integer()();
  DateTimeColumn get effectiveFrom => dateTime()();
  DateTimeColumn get effectiveUntil => dateTime().nullable()();
  RealColumn get maxPoint => real()();
  TextColumn get grades => text().map(const GradeDefinitionListConverter())();
  TextColumn get classifications =>
      text().map(const ClassificationBandListConverter())();
  TextColumn get repeatPolicy => textEnum<RepeatPolicy>()();
  RealColumn get repeatCapPoint => real().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

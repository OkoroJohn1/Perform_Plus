/// The local SQLite database — source of truth for offline-first academic
/// records. See AGENTS.md: the CGPA engine is pure computation and must
/// run with zero network, so this is where everything actually lives until
/// a Supabase mirror is added.
library;

import 'package:drift/drift.dart';

import '../../domain/models/course_result.dart';
import '../../domain/models/grading_scheme.dart';
import 'connection/connection_unsupported.dart'
    if (dart.library.io) 'connection/connection_native.dart'
    if (dart.library.js_interop) 'connection/connection_web.dart'
    as platform;
import 'converters/classification_band_list_converter.dart';
import 'converters/grade_definition_list_converter.dart';
import 'daos/course_result_dao.dart';
import 'daos/goal_dao.dart';
import 'daos/grading_scheme_dao.dart';
import 'daos/profile_dao.dart';
import 'daos/semester_dao.dart';
import 'tables/course_results_table.dart';
import 'tables/goals_table.dart';
import 'tables/grading_schemes_table.dart';
import 'tables/profiles_table.dart';
import 'tables/semesters_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Profiles, Semesters, CourseResults, GradingSchemes, Goals],
  daos: [ProfileDao, SemesterDao, CourseResultDao, GradingSchemeDao, GoalDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(platform.connect());

  /// For tests: pass `NativeDatabase.memory()` (or any `QueryExecutor`) so
  /// nothing touches the real filesystem/platform channels.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (Migrator m) => m.createAll());
}

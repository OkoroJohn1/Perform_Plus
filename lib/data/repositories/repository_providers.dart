/// The whole persistence-layer dependency graph in one place: the database
/// instance and the four repository providers. Screens/other providers
/// depend on the `Provider<XRepository>`s here, never on `AppDatabase` or
/// Drift types directly — this is the single swap point when a remote-sync
/// repository is added later.
///
/// Any widget test that touches this provider tree must override
/// [appDatabaseProvider] with `AppDatabase.forTesting(NativeDatabase.memory())`
/// — the real constructor hits platform channels (`path_provider`) and will
/// throw/hang in a plain `flutter test` run.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/academic_record_repository.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/grading_scheme_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../local/app_database.dart';
import 'drift_academic_record_repository.dart';
import 'drift_goal_repository.dart';
import 'drift_grading_scheme_repository.dart';
import 'drift_profile_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final academicRecordRepositoryProvider = Provider<AcademicRecordRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftAcademicRecordRepository(db.semesterDao, db.courseResultDao);
});

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => DriftProfileRepository(ref.watch(appDatabaseProvider).profileDao),
);

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => DriftGoalRepository(ref.watch(appDatabaseProvider).goalDao),
);

final gradingSchemeRepositoryProvider = Provider<GradingSchemeRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftGradingSchemeRepository(db.gradingSchemeDao, db.profileDao);
});

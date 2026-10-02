import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:perform_plus/core/router/routes.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/academic_record_provider.dart';
import 'package:perform_plus/data/repositories/drift_profile_repository.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/data/seed/nigerian_institutions.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/domain/models/student_profile.dart';
import 'package:perform_plus/features/onboarding/screens/backfill_screen.dart';

final _now = DateTime(2026, 1, 1);

Semester _semester(int level, SemesterTerm term) => Semester(
      id: '$level-${term.name}',
      profileId: 'local-profile',
      session: '2024/2025',
      term: term,
      level: level,
      results: [
        CourseResult(
          id: '$level-${term.name}-CSC101',
          semesterId: '$level-${term.name}',
          courseCode: 'CSC101',
          creditUnit: 3,
          grade: 'A',
          createdAt: _now,
          updatedAt: _now,
        ),
      ],
      createdAt: _now,
      updatedAt: _now,
    );

const _profile = StudentProfile(
  fullName: 'Ada Obi',
  regNumber: '20211258122',
  department: 'Computer Science',
  currentLevel: 300,
  entryYear: 2021,
  expectedGraduationYear: 2026,
);

Future<AppDatabase> _seededDb(StudentProfile profile) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await DriftProfileRepository(db.profileDao).saveProfile(profile);
  return db;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('term labels come from the active scheme, not hardcoded',
      (tester) async {
    final db = await _seededDb(_profile);
    final record = AcademicRecord(
      semesters: [_semester(300, SemesterTerm.first)],
      scheme: defaultSchemes['futo']!,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          academicRecordProvider.overrideWith(
            (ref) => AcademicRecordController.seeded(record),
          ),
        ],
        child: const MaterialApp(home: BackfillScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 100L, 200L and the current 300L first term all render "Harmattan
    // Semester"; 100L/200L's second term renders "Rain Semester".
    expect(find.text('Harmattan Semester'), findsNWidgets(3));
    expect(find.text('Rain Semester'), findsNWidgets(2));
    expect(find.text('First Semester'), findsNothing);
    expect(find.text('Second Semester'), findsNothing);
  });

  testWidgets(
      'a 300L student sees the derived count, never a 400L/500L/600L row',
      (tester) async {
    final db = await _seededDb(_profile);
    final record = AcademicRecord(
      semesters: [_semester(300, SemesterTerm.first)],
      scheme: defaultSchemes['futo']!,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          academicRecordProvider.overrideWith(
            (ref) => AcademicRecordController.seeded(record),
          ),
        ],
        child: const MaterialApp(home: BackfillScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final counter = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((w) => w.text.toPlainText())
        .where((t) => t.contains('semesters added'));
    expect(counter, contains('1 of 5 semesters added'));
    expect(find.text('400 Level'), findsNothing);
    expect(find.text('500 Level'), findsNothing);
    expect(find.text('600 Level'), findsNothing);
  });

  testWidgets(
      'a first-semester student with nothing left to backfill skips straight '
      'to goal setting', (tester) async {
    final firstYearProfile = _profile.copyWith(currentLevel: 100);
    final db = await _seededDb(firstYearProfile);
    final record = AcademicRecord(
      semesters: [_semester(100, SemesterTerm.first)],
      scheme: defaultSchemes['futo']!,
    );

    final router = GoRouter(
      initialLocation: Routes.backfill,
      routes: [
        GoRoute(
          path: Routes.backfill,
          builder: (context, state) => const BackfillScreen(),
        ),
        GoRoute(
          path: Routes.goalSetting,
          builder: (context, state) => const Text('GOAL SETTING SCREEN'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          academicRecordProvider.overrideWith(
            (ref) => AcademicRecordController.seeded(record),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GOAL SETTING SCREEN'), findsOneWidget);
    expect(find.byType(BackfillScreen), findsNothing);
  });
}

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/academic_record_provider.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/data/seed/nigerian_institutions.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/features/academics/screens/roadmap_view.dart';

final _now = DateTime(2026, 1, 1);
final _scheme = defaultSchemes['futo']!;

CourseResult _r(String code, String semesterId) => CourseResult(
      id: '$semesterId-$code',
      semesterId: semesterId,
      courseCode: code,
      creditUnit: 3,
      grade: 'B',
      createdAt: _now,
      updatedAt: _now,
    );

Semester _s(String id, int level, SemesterTerm term) => Semester(
      id: id,
      profileId: 'local-profile',
      session: '2024/2025',
      term: term,
      level: level,
      results: [_r('CSC101', id)],
      createdAt: _now,
      updatedAt: _now,
    );

Widget _app(List<Semester> semesters) => ProviderScope(
      overrides: [
        academicRecordProvider.overrideWith(
          (ref) => AcademicRecordController.seeded(
            AcademicRecord(semesters: semesters, scheme: _scheme),
          ),
        ),
        appDatabaseProvider.overrideWithValue(AppDatabase.forTesting(NativeDatabase.memory())),
      ],
      child: const MaterialApp(home: Scaffold(body: RoadmapView())),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('a level with only one term uploaded shows as partial, not complete',
      (tester) async {
    await tester.pumpWidget(_app([_s('s1', 100, SemesterTerm.first)]));
    await tester.pumpAndSettle();

    expect(find.text('1 of 2 semesters uploaded'), findsOneWidget);
    expect(find.text('Both semesters uploaded'), findsNothing);
    expect(find.byIcon(Icons.adjust), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('a level only ticks complete once both terms of the session are uploaded',
      (tester) async {
    await tester.pumpWidget(_app([
      _s('s1', 100, SemesterTerm.first),
      _s('s2', 100, SemesterTerm.second),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Both semesters uploaded'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('1 of 2 semesters uploaded'), findsNothing);
  });

  testWidgets('every level label renders with visible (non-white) text on the light surface',
      (tester) async {
    await tester.pumpWidget(_app([_s('s1', 100, SemesterTerm.first)]));
    await tester.pumpAndSettle();

    final label = tester.widget<Text>(find.text('100 Level'));
    expect(label.style?.color, isNot(Colors.white));
  });
}

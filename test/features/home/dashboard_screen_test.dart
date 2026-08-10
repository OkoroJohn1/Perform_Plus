import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/repositories/academic_record_provider.dart';
import 'package:perform_plus/data/seed/nigerian_institutions.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/features/home/screens/dashboard_screen.dart';

final _now = DateTime(2026, 1, 1);

CourseResult _r(String code, int unit, String grade, String semesterId) =>
    CourseResult(
      id: '$semesterId-$code',
      semesterId: semesterId,
      courseCode: code,
      creditUnit: unit,
      grade: grade,
      createdAt: _now,
      updatedAt: _now,
    );

Semester _s(String id, int level, SemesterTerm term, List<CourseResult> r) =>
    Semester(
      id: id,
      profileId: 'p1',
      session: '2024/2025',
      term: term,
      level: level,
      results: r,
      createdAt: _now,
      updatedAt: _now,
    );

Widget _appWith(AcademicRecord record) => ProviderScope(
      overrides: [
        academicRecordProvider.overrideWith(
          (ref) => AcademicRecordController.seeded(record),
        ),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    );

void main() {
  testWidgets('empty record shows the empty state, not a loading spinner',
      (tester) async {
    await tester.pumpWidget(
      _appWith(AcademicRecord(semesters: const [], scheme: fallbackScheme)),
    );

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Add your first results'), findsOneWidget);
  });

  testWidgets('one semester renders the trend placeholder, not a chart',
      (tester) async {
    final semester = _s('s1', 100, SemesterTerm.first, [
      _r('CSC101', 3, 'A', 's1'),
      _r('MTH101', 3, 'B', 's1'),
    ]);

    await tester.pumpWidget(
      _appWith(AcademicRecord(semesters: [semester], scheme: fallbackScheme)),
    );

    expect(
      find.text('Add another semester to see your trend'),
      findsOneWidget,
    );
    // The CGPA card still renders with real numbers in the partial state.
    expect(find.textContaining('4.5'), findsWidgets);
  });

  testWidgets('two or more semesters render the trend chart', (tester) async {
    final semesters = [
      _s('s1', 100, SemesterTerm.first, [_r('CSC101', 3, 'A', 's1')]),
      _s('s2', 100, SemesterTerm.second, [_r('MTH101', 3, 'B', 's2')]),
    ];

    await tester.pumpWidget(
      _appWith(AcademicRecord(semesters: semesters, scheme: fallbackScheme)),
    );

    expect(
      find.text('Add another semester to see your trend'),
      findsNothing,
    );
    expect(find.text('CGPA trend'), findsOneWidget);
  });
}

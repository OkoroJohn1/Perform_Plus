import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/academic_record_provider.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/data/seed/nigerian_institutions.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/features/academics/screens/results_view.dart';

final _now = DateTime(2026, 1, 1);
final _scheme = defaultSchemes['futo']!;

CourseResult _r(String code, int unit, String grade, String semesterId) => CourseResult(
      id: '$semesterId-$code',
      semesterId: semesterId,
      courseCode: code,
      creditUnit: unit,
      grade: grade,
      createdAt: _now,
      updatedAt: _now,
    );

Semester _s(String id, int level, SemesterTerm term, List<CourseResult> r) => Semester(
      id: id,
      profileId: 'p1',
      session: '2024/2025',
      term: term,
      level: level,
      results: r,
      createdAt: _now,
      updatedAt: _now,
    );

// The Results screen's new Result slip wallet card reads a Drift-backed
// provider -- `appDatabaseProvider` must be overridden with an in-memory
// instance or the real constructor hits `path_provider`'s platform channel
// and throws, same as every other Drift-touching widget test here (see
// `repository_providers.dart`'s doc comment).
Widget _app(List<Semester> semesters) => ProviderScope(
      overrides: [
        academicRecordProvider.overrideWith(
          (ref) => AcademicRecordController.seeded(
            AcademicRecord(semesters: semesters, scheme: _scheme),
          ),
        ),
        appDatabaseProvider.overrideWithValue(AppDatabase.forTesting(NativeDatabase.memory())),
      ],
      child: const MaterialApp(home: Scaffold(body: ResultsView())),
    );

void main() {
  testWidgets('a semester row shows its own GPA and the running CGPA as distinct values',
      (tester) async {
    // sem1: 10 units at C (3.0) -> gpa 3.00, cgpa-then 3.00.
    // sem2: 10 units at A (5.0) -> gpa 5.00, cgpa-then (30+50)/20 = 4.00.
    // The most recent row (sem2) must show 5.00 and 4.00 -- never the same
    // number under both labels, and never CGPA where GPA belongs.
    final semesters = [
      _s('s1', 100, SemesterTerm.first, [_r('CSC101', 10, 'C', 's1')]),
      _s('s2', 100, SemesterTerm.second, [_r('MTH101', 10, 'A', 's2')]),
    ];

    await tester.pumpWidget(_app(semesters));
    await tester.pumpAndSettle();

    // Both "5.00" and "4.00" also legitimately appear elsewhere on the page
    // (the hero's current CGPA and the best-semester tile happen to match
    // the most recent semester's own figures) -- scope to the row itself to
    // prove the GPA and CGPA-then columns within it are genuinely distinct.
    final row = find.byKey(const ValueKey('semesterRowTap-s2'));
    expect(find.descendant(of: row, matching: find.text('GPA')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('CGPA then')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('5.00')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('4.00')), findsOneWidget);
  });

  testWidgets('term labels come from the scheme, not a hardcoded 1st/2nd',
      (tester) async {
    final semesters = [
      _s('s1', 100, SemesterTerm.first, [_r('CSC101', 3, 'A', 's1')]),
    ];

    await tester.pumpWidget(_app(semesters));
    await tester.pumpAndSettle();

    // FUTO calls it Harmattan Semester, never the generic "1st Semester".
    expect(find.text('Harmattan Semester'), findsOneWidget);
    expect(find.text('1st Semester'), findsNothing);
  });

  group('carryover section', () {
    testWidgets('does not appear when there are no retakes or failing grades',
        (tester) async {
      final semesters = [
        _s('s1', 100, SemesterTerm.first, [_r('CSC101', 3, 'A', 's1')]),
        _s('s2', 100, SemesterTerm.second, [_r('MTH101', 3, 'B', 's2')]),
      ];

      await tester.pumpWidget(_app(semesters));
      await tester.pumpAndSettle();

      expect(find.text('Carryovers'), findsNothing);
    });

    testWidgets('appears for a single failing attempt that was never retaken',
        (tester) async {
      final semesters = [
        _s('s1', 100, SemesterTerm.first, [
          _r('CSC101', 3, 'A', 's1'),
          _r('MTH101', 3, 'F', 's1'),
        ]),
      ];

      await tester.pumpWidget(_app(semesters));
      await tester.pumpAndSettle();

      // The carryover card sits below the performance summary, past the
      // default test viewport's fold -- ListView only realises elements
      // once they're scrolled into (or near) view.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(find.text('Carryovers'), findsOneWidget);
      expect(find.text('MTH101'), findsOneWidget);
      expect(find.text('Outstanding'), findsOneWidget);
    });
  });

  testWidgets('deleting a semester shows the recalculation delta with an Undo action',
      (tester) async {
    final semesters = [
      _s('s1', 100, SemesterTerm.first, [_r('CSC101', 10, 'C', 's1')]),
      _s('s2', 100, SemesterTerm.second, [_r('MTH101', 10, 'A', 's2')]),
    ];

    await tester.pumpWidget(_app(semesters));
    await tester.pumpAndSettle();

    // Standing starts at cgpa 4.00 (see the GPA/CGPA test above for the
    // arithmetic); open the most recent semester (s2) and delete it, which
    // should drop the CGPA back to 3.00.
    await tester.tap(find.byKey(const ValueKey('semesterRowTap-s2')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete semester'));
    await tester.pumpAndSettle();

    expect(find.textContaining('CGPA 4.00'), findsOneWidget);
    expect(find.textContaining('3.00'), findsWidgets);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('one semester hides the recent-trend tile and delta indicators',
      (tester) async {
    final semesters = [
      _s('s1', 100, SemesterTerm.first, [_r('CSC101', 10, 'B', 's1')]),
    ];

    await tester.pumpWidget(_app(semesters));
    await tester.pumpAndSettle();

    expect(find.text('Recent trend'), findsNothing);
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
    expect(find.byIcon(Icons.arrow_downward), findsNothing);
    // The rest of the record still renders normally -- below the fold now
    // that the Result slip wallet card sits above it, so it needs a scroll
    // into view first, same as the "Grade Breakdown" assertion below.
    await tester.scrollUntilVisible(
      find.text('Best semester'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Best semester'), findsOneWidget);
  });

  testWidgets("a semester's grade table only appears once its dropdown is tapped",
      (tester) async {
    final semesters = [
      _s('s1', 100, SemesterTerm.first, [
        _r('CSC101', 3, 'A', 's1'),
        _r('MTH101', 3, 'B', 's1'),
      ]),
    ];

    await tester.pumpWidget(_app(semesters));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Grade Breakdown'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Grade Breakdown'), findsOneWidget);
    // Collapsed by default -- the per-grade table isn't in the tree yet.
    expect(find.text('Courses'), findsNothing);
    expect(find.text('Points'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('gradeBreakdownToggle-s1')));
    await tester.pumpAndSettle();

    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Points'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    // Tapping again collapses it back.
    await tester.tap(find.byKey(const ValueKey('gradeBreakdownToggle-s1')));
    await tester.pumpAndSettle();

    expect(find.text('Courses'), findsNothing);
  });
}

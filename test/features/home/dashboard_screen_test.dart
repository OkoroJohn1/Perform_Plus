import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/core/theme/app_theme.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/academic_record_provider.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/data/seed/nigerian_institutions.dart';
import 'package:perform_plus/domain/engine/cgpa_engine.dart';
import 'package:perform_plus/domain/engine/projection_solver.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/domain/models/student_profile.dart';
import 'package:perform_plus/features/home/screens/dashboard_screen.dart';
import 'package:perform_plus/features/home/widgets/cgpa_card.dart';
import 'package:perform_plus/features/home/widgets/credit_load_split_card.dart';
import 'package:perform_plus/features/home/widgets/next_action_card.dart';
import 'package:perform_plus/features/home/widgets/trend_chart.dart';

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

SemesterComputation _comp({
  required String id,
  int level = 100,
  SemesterTerm term = SemesterTerm.first,
  required double gpa,
  int creditUnits = 20,
  List<ExcludedResult> excluded = const [],
}) =>
    SemesterComputation(
      semesterId: id,
      level: level,
      term: term,
      session: '2024/2025',
      qualityPoints: gpa * creditUnits,
      creditUnits: creditUnits,
      creditsPassed: creditUnits,
      gpa: gpa,
      excluded: excluded,
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('goal-ring progress (band-floor-relative, not a raw ratio)', () {
    test('matches the worked example from the task brief', () {
      // Current 4.32, targeting First Class (min 4.50). The band below
      // First Class is 2:1, whose floor is 3.50. (4.32-3.50)/(4.50-3.50)
      // = 0.82 -- a materially different (and more honest) number than the
      // raw ratio 4.32/4.50 ~= 0.96, which would flatter a student who has
      // barely entered the target band.
      final target = _scheme.classifications.firstWhere((b) => b.shortLabel == 'First Class');
      final projection = TargetProjection(
        targetCgpa: target.minCgpa,
        targetLabel: target.label,
        currentCgpa: 4.32,
        creditsEarned: 100,
        creditsRemaining: 40,
        semestersRemaining: 2,
        requiredAverage: 5.0,
        feasibility: Feasibility.demanding,
        ceilingCgpa: 4.9,
        coastingCgpa: 4.32,
      );

      final progress = goalRingProgress(_scheme, projection);
      final rawRatio = projection.currentCgpa / projection.targetCgpa;

      expect(progress, closeTo(0.82, 0.005));
      expect((progress - rawRatio).abs() > 0.1, isTrue);
    });

    test('floors at zero for a target that is already the lowest band', () {
      final pass = _scheme.classifications.firstWhere((b) => b.shortLabel == 'Pass');
      expect(goalRingFloor(_scheme, pass.minCgpa), 0.0);
    });
  });

  group('feasibility colour mapping on the hero ring', () {
    TargetProjection projectionWith(Feasibility feasibility) => TargetProjection(
          targetCgpa: 3.50,
          targetLabel: 'Second Class Honours (Upper Division)',
          currentCgpa: 2.5,
          creditsEarned: 50,
          creditsRemaining: 80,
          semestersRemaining: 4,
          requiredAverage: 4.13,
          feasibility: feasibility,
          personalBest: 3.2,
          ceilingCgpa: 4.9,
          coastingCgpa: 2.5,
        );

    Future<void> pumpCard(WidgetTester tester, TargetProjection goal) => tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CgpaCard(
                standing: AcademicStanding.empty,
                scheme: _scheme,
                goal: goal,
                goalBand: null,
                onSetGoal: () {},
              ),
            ),
          ),
        );

    testWidgets('demanding renders the amber-yellow ring colour', (tester) async {
      await pumpCard(tester, projectionWith(Feasibility.demanding));
      await tester.pumpAndSettle();

      expect(find.text('Demanding'), findsOneWidget);
      final text = tester.widget<Text>(find.text('Demanding'));
      expect(text.style?.color, DashboardPalette.ringDemanding);
    });

    testWidgets('unreachable renders "Out of reach" in dimmed white, not red',
        (tester) async {
      await pumpCard(tester, projectionWith(Feasibility.unreachable));
      await tester.pumpAndSettle();

      expect(find.text('Out of reach'), findsOneWidget);
      final text = tester.widget<Text>(find.text('Out of reach'));
      expect(text.style?.color, Colors.white.withValues(alpha: 0.45));
    });

    testWidgets('secured and comfortable share the same green', (tester) async {
      await pumpCard(tester, projectionWith(Feasibility.secured));
      await tester.pumpAndSettle();
      final secured = tester.widget<Text>(find.text('Secured')).style?.color;

      await pumpCard(tester, projectionWith(Feasibility.comfortable));
      await tester.pumpAndSettle();
      final comfortable = tester.widget<Text>(find.text('Comfortable')).style?.color;

      expect(secured, DashboardPalette.ringSecured);
      expect(comfortable, DashboardPalette.ringSecured);
    });
  });

  testWidgets('a single semester falls back to the placeholder, not an empty chart',
      (tester) async {
    final standing = AcademicStanding(
      cgpa: 4.0,
      totalQualityPoints: 80,
      totalCreditUnits: 20,
      totalCreditsPassed: 20,
      semesters: [_comp(id: 's1', gpa: 4.0)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrendCard(standing: standing, scheme: _scheme, rawSemesters: const [], goal: null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add one more semester to see your trend'), findsOneWidget);
    expect(find.byType(TrendPlaceholder), findsOneWidget);
  });

  group('next-action priority ordering', () {
    final profile = StudentProfile(
      fullName: 'Ada Obi',
      regNumber: '20211258122',
      department: 'Computer Science',
      currentLevel: 300,
      entryYear: 2022,
      expectedGraduationYear: 2027,
    );

    final goal = TargetProjection(
      targetCgpa: 3.5,
      currentCgpa: 4.0,
      creditsEarned: 60,
      creditsRemaining: 40,
      semestersRemaining: 2,
      requiredAverage: 2.5,
      feasibility: Feasibility.secured,
      ceilingCgpa: 4.9,
      coastingCgpa: 4.0,
    );

    test('priority 1: a semester before the current level is missing', () {
      // 300L with only 100L first term on record -- 100L second, 200L
      // first/second and 300L first are all missing; the earliest is
      // 100L second.
      final raw = [_s('s1', 100, SemesterTerm.first, [_r('CSC101', 3, 'A', 's1')])];
      final standing = AcademicStanding(
        cgpa: 5.0,
        totalQualityPoints: 15,
        totalCreditUnits: 3,
        totalCreditsPassed: 3,
        semesters: [_comp(id: 's1', gpa: 5.0, creditUnits: 3)],
      );

      final action = resolveNextAction(
        standing: standing,
        rawSemesters: raw,
        scheme: _scheme,
        profile: profile,
        goal: goal,
      );

      expect(action.text, contains('100L'));
      expect(action.text, startsWith('Add your'));
    });

    test('priority 2: no missing backfill, but no goal set', () {
      final level300Profile = StudentProfile(
        fullName: 'Ada Obi',
        regNumber: '20211258122',
        department: 'Computer Science',
        currentLevel: 100,
        entryYear: 2025,
        expectedGraduationYear: 2029,
      );
      final raw = [_s('s1', 100, SemesterTerm.first, [_r('CSC101', 3, 'A', 's1')])];
      final standing = AcademicStanding(
        cgpa: 5.0,
        totalQualityPoints: 15,
        totalCreditUnits: 3,
        totalCreditsPassed: 3,
        semesters: [_comp(id: 's1', gpa: 5.0, creditUnits: 3)],
      );

      final action = resolveNextAction(
        standing: standing,
        rawSemesters: raw,
        scheme: _scheme,
        profile: level300Profile,
        goal: null,
      );

      expect(action.text, 'Set your target classification');
    });

    test('priority 3: goal set and backfill complete, but fewer than two semesters', () {
      final level100Profile = StudentProfile(
        fullName: 'Ada Obi',
        regNumber: '20211258122',
        department: 'Computer Science',
        currentLevel: 100,
        entryYear: 2025,
        expectedGraduationYear: 2029,
      );
      final raw = [_s('s1', 100, SemesterTerm.first, [_r('CSC101', 3, 'A', 's1')])];
      final standing = AcademicStanding(
        cgpa: 5.0,
        totalQualityPoints: 15,
        totalCreditUnits: 3,
        totalCreditsPassed: 3,
        semesters: [_comp(id: 's1', gpa: 5.0, creditUnits: 3)],
      );

      final action = resolveNextAction(
        standing: standing,
        rawSemesters: raw,
        scheme: _scheme,
        profile: level100Profile,
        goal: goal,
      );

      expect(action.text, 'Add another semester to unlock your trend');
    });

    test('priority 4: otherwise, prompt for the next semester in sequence', () {
      final level100Profile = StudentProfile(
        fullName: 'Ada Obi',
        regNumber: '20211258122',
        department: 'Computer Science',
        currentLevel: 100,
        entryYear: 2025,
        expectedGraduationYear: 2029,
      );
      final raw = [
        _s('s1', 100, SemesterTerm.first, [_r('CSC101', 3, 'A', 's1')]),
        _s('s2', 100, SemesterTerm.second, [_r('MTH101', 3, 'A', 's2')]),
      ];
      final standing = AcademicStanding(
        cgpa: 5.0,
        totalQualityPoints: 30,
        totalCreditUnits: 6,
        totalCreditsPassed: 6,
        semesters: [
          _comp(id: 's1', gpa: 5.0, creditUnits: 3),
          _comp(id: 's2', gpa: 5.0, creditUnits: 3, term: SemesterTerm.second),
        ],
      );

      final action = resolveNextAction(
        standing: standing,
        rawSemesters: raw,
        scheme: _scheme,
        profile: level100Profile,
        goal: goal,
      );

      // Backfill for a 100L student with both terms on record expects
      // nothing more; next in sequence is 200L, first term.
      expect(action.text, 'Add 200L ${_scheme.termLabel(SemesterTerm.first)} results');
    });
  });

  testWidgets('credit split groups counted courses by grade standard, not by GPA',
      (tester) async {
    final raw = [
      _s('s1', 100, SemesterTerm.first, [
        _r('CSC101', 10, 'A', 's1'),
        _r('MTH101', 6, 'B', 's1'),
      ]),
      _s('s2', 100, SemesterTerm.second, [
        _r('PHY101', 4, 'C', 's2'),
        _r('CHM101', 3, 'F', 's2'),
      ]),
      _s('s3', 200, SemesterTerm.first, [
        _r('CSC201', 5, 'D', 's3'),
      ]),
    ];
    final standing = AcademicStanding(
      cgpa: 3.0,
      totalQualityPoints: 90,
      totalCreditUnits: 28,
      totalCreditsPassed: 25,
      semesters: [
        _comp(id: 's1', gpa: 4.6, creditUnits: 16),
        _comp(id: 's2', gpa: 1.7, creditUnits: 7, term: SemesterTerm.second),
        _comp(id: 's3', gpa: 2.0, level: 200, creditUnits: 5),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreditLoadSplitCard(standing: standing, rawSemesters: raw),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('10 units at A'), findsOneWidget);
    expect(find.text('6 units at B'), findsOneWidget);
    expect(find.text('4 units at C'), findsOneWidget);
    expect(find.text('3 units at F'), findsOneWidget);
    expect(find.text('5 units at D'), findsOneWidget);
  });

  testWidgets('credit split is hidden below three semesters', (tester) async {
    final raw = [
      _s('s1', 100, SemesterTerm.first, [_r('CSC101', 10, 'A', 's1')]),
      _s('s2', 100, SemesterTerm.second, [_r('MTH101', 6, 'B', 's2')]),
    ];
    final standing = AcademicStanding(
      cgpa: 4.6,
      totalQualityPoints: 74,
      totalCreditUnits: 16,
      totalCreditsPassed: 16,
      semesters: [_comp(id: 's1', gpa: 5.0, creditUnits: 10), _comp(id: 's2', gpa: 4.0, creditUnits: 6)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CreditLoadSplitCard(standing: standing, rawSemesters: raw)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Where your credits sit'), findsNothing);
  });

  testWidgets('empty dashboard shows the honest empty state, not a loading spinner',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          academicRecordProvider.overrideWith(
            (ref) => AcademicRecordController.seeded(
              AcademicRecord(semesters: const [], scheme: fallbackScheme),
            ),
          ),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your dashboard is waiting'), findsOneWidget);
    expect(find.text('Add your first semester'), findsOneWidget);
  });
}

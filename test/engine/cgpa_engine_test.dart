import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/seed/nigerian_institutions.dart';
import 'package:perform_plus/domain/engine/cgpa_engine.dart';
import 'package:perform_plus/domain/engine/projection_solver.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/domain/models/grading_scheme.dart';

final _now = DateTime(2026, 1, 1);

CourseResult _r(
  String code,
  int unit,
  String grade, {
  String semesterId = 's1',
  int attempt = 1,
  String? id,
}) =>
    CourseResult(
      id: id ?? '$semesterId-$code-$attempt',
      semesterId: semesterId,
      courseCode: code,
      creditUnit: unit,
      grade: grade,
      attempt: attempt,
      createdAt: _now,
      updatedAt: _now,
    );

Semester _s(
  String id,
  int level,
  SemesterTerm term,
  List<CourseResult> results,
) =>
    Semester(
      id: id,
      profileId: 'p1',
      session: '2024/2025',
      term: term,
      level: level,
      results: results,
      createdAt: _now,
      updatedAt: _now,
    );

void main() {
  final scheme = defaultSchemes['futo']!;

  group('scheme integrity', () {
    test('all seeded schemes validate', () {
      for (final entry in defaultSchemes.entries) {
        expect(
          entry.value.validate(),
          isEmpty,
          reason: 'Scheme "${entry.key}" failed validation',
        );
      }
    });

    test('classification bands cover the boundaries correctly', () {
      expect(scheme.classify(5.00)?.shortLabel, 'First Class');
      expect(scheme.classify(4.50)?.shortLabel, 'First Class');
      expect(scheme.classify(4.49)?.shortLabel, '2:1');
      expect(scheme.classify(3.50)?.shortLabel, '2:1');
      expect(scheme.classify(3.49)?.shortLabel, '2:2');
      expect(scheme.classify(2.40)?.shortLabel, '2:2');
      expect(scheme.classify(2.39)?.shortLabel, 'Third Class');
    });

    test('score maps to the correct letter', () {
      expect(scheme.letterForScore(85), 'A');
      expect(scheme.letterForScore(70), 'A');
      expect(scheme.letterForScore(69), 'B');
      expect(scheme.letterForScore(39), 'F');
    });
  });

  group('semester GPA', () {
    test('computes a straightforward semester', () {
      // 5*3 + 4*3 + 5*2 + 3*2 + 5*2 = 15+12+10+6+10 = 53 over 12 units
      final semester = _s('s1', 300, SemesterTerm.first, [
        _r('CSC301', 3, 'A'),
        _r('MTH301', 3, 'B'),
        _r('PHY301', 2, 'A'),
        _r('GST301', 2, 'C'),
        _r('CSC303', 2, 'A'),
      ]);

      final result = CgpaEngine.computeSemester(
        semester: semester,
        scheme: scheme,
      );

      expect(result.creditUnits, 12);
      expect(result.qualityPoints, 53);
      expect(result.gpa, closeTo(4.42, 0.01));
    });

    test('a failing grade counts in the denominator but adds no points', () {
      final semester = _s('s1', 100, SemesterTerm.first, [
        _r('CSC101', 3, 'A'),
        _r('MTH101', 3, 'F'),
      ]);

      final result =
          CgpaEngine.computeSemester(semester: semester, scheme: scheme);

      expect(result.creditUnits, 6);
      expect(result.creditsPassed, 3);
      expect(result.qualityPoints, 15);
      expect(result.gpa, 2.50);
    });

    test('an empty semester yields zero, not a division error', () {
      final semester = _s('s1', 100, SemesterTerm.first, []);
      final result =
          CgpaEngine.computeSemester(semester: semester, scheme: scheme);

      expect(result.gpa, 0);
      expect(result.creditUnits, 0);
    });

    test('an unknown grade is excluded and reported, never silently zeroed',
        () {
      final issues = <CalculationIssue>[];
      final semester = _s('s1', 100, SemesterTerm.first, [
        _r('CSC101', 3, 'A'),
        _r('MTH101', 3, 'Z'),
      ]);

      final result = CgpaEngine.computeSemester(
        semester: semester,
        scheme: scheme,
        issueSink: issues,
      );

      // Only the valid row counts. A silent zero would have given 2.50,
      // which looks plausible and would be wrong.
      expect(result.creditUnits, 3);
      expect(result.gpa, 5.0);
      expect(result.excluded.length, 1);
      expect(issues.single.severity, IssueSeverity.error);
    });
  });

  group('cumulative standing', () {
    test('CGPA weights by credit unit, not by semester average', () {
      // A 5.0 over 6 units then a 3.0 over 18 units is NOT 4.0.
      final semesters = [
        _s('s1', 100, SemesterTerm.first, [_r('A101', 6, 'A')]),
        _s('s2', 100, SemesterTerm.second,
            [_r('B101', 18, 'C', semesterId: 's2')]),
      ];

      final standing = CgpaEngine.computeStanding(
        semesters: semesters,
        scheme: scheme,
      );

      // (5*6 + 3*18) / 24 = 84/24 = 3.5
      expect(standing.cgpa, 3.50);
      expect(standing.classification?.shortLabel, '2:1');
    });

    test('semesters are ordered chronologically regardless of input order',
        () {
      final semesters = [
        _s('s3', 200, SemesterTerm.first, [_r('C201', 3, 'A')]),
        _s('s1', 100, SemesterTerm.first, [_r('A101', 3, 'C')]),
        _s('s2', 100, SemesterTerm.second, [_r('B101', 3, 'B')]),
      ];

      final standing =
          CgpaEngine.computeStanding(semesters: semesters, scheme: scheme);

      expect(
        standing.semesters.map((s) => s.shortLabel).toList(),
        ['100L 1st', '100L 2nd', '200L 1st'],
      );
    });

    test('tracks best semester GPA for honest feasibility framing', () {
      final semesters = [
        _s('s1', 100, SemesterTerm.first, [_r('A101', 3, 'B')]),
        _s('s2', 100, SemesterTerm.second,
            [_r('B101', 3, 'A', semesterId: 's2')]),
        _s('s3', 200, SemesterTerm.first,
            [_r('C201', 3, 'C', semesterId: 's3')]),
      ];

      final standing =
          CgpaEngine.computeStanding(semesters: semesters, scheme: scheme);

      expect(standing.bestSemesterGpa, 5.0);
      expect(standing.worstSemesterGpa, 3.0);
    });

    test('no data yields the empty standing rather than NaN', () {
      final standing =
          CgpaEngine.computeStanding(semesters: [], scheme: scheme);
      expect(standing.cgpa, 0);
      expect(standing.hasData, isFalse);
    });

    test('cumulative trend is running CGPA-to-date, not per-semester GPA',
        () {
      final semesters = [
        _s('s1', 100, SemesterTerm.first, [_r('A101', 6, 'A')]),
        _s('s2', 100, SemesterTerm.second,
            [_r('B101', 18, 'C', semesterId: 's2')]),
      ];

      final standing =
          CgpaEngine.computeStanding(semesters: semesters, scheme: scheme);

      // After s1: 5.0. After s1+s2: (5*6 + 3*18)/24 = 3.50 (the final CGPA).
      expect(standing.cumulativeCgpaTrend, [5.0, 3.50]);
    });
  });

  group('carryover policy', () {
    final failThenRepeat = [
      _s('s1', 100, SemesterTerm.first, [
        _r('MTH101', 3, 'F'),
        _r('CSC101', 3, 'A'),
      ]),
      _s('s2', 200, SemesterTerm.first, [
        _r('MTH101', 3, 'B', semesterId: 's2', attempt: 2),
      ]),
    ];

    test('countBothAttempts keeps the original failure in the denominator',
        () {
      final s = scheme.copyWith(repeatPolicy: RepeatPolicy.countBothAttempts);
      final standing =
          CgpaEngine.computeStanding(semesters: failThenRepeat, scheme: s);

      // (0*3 + 5*3 + 4*3) / 9 = 27/9 = 3.0
      expect(standing.totalCreditUnits, 9);
      expect(standing.cgpa, 3.00);
    });

    test('replaceOriginal drops the superseded failure entirely', () {
      final s = scheme.copyWith(repeatPolicy: RepeatPolicy.replaceOriginal);
      final standing =
          CgpaEngine.computeStanding(semesters: failThenRepeat, scheme: s);

      // (5*3 + 4*3) / 6 = 27/6 = 4.5
      expect(standing.totalCreditUnits, 6);
      expect(standing.cgpa, 4.50);
    });

    test('replaceWithCap limits the repeat grade to the cap', () {
      final s = scheme.copyWith(
        repeatPolicy: RepeatPolicy.replaceWithCap,
        repeatCapPoint: 3.0,
      );
      final standing =
          CgpaEngine.computeStanding(semesters: failThenRepeat, scheme: s);

      // The B (4.0) is capped to 3.0: (0*3 + 5*3 + 3*3) / 9 = 24/9 = 2.67
      expect(standing.cgpa, closeTo(2.67, 0.01));
    });

    test('policy choice materially changes the outcome', () {
      // This is the whole point: the same transcript produces 3.00, 4.50,
      // or 2.67 depending on policy. Guessing here is not acceptable.
      final results = [
        RepeatPolicy.countBothAttempts,
        RepeatPolicy.replaceOriginal,
      ].map((p) => CgpaEngine.computeStanding(
            semesters: failThenRepeat,
            scheme: scheme.copyWith(repeatPolicy: p),
          ).cgpa);

      expect(results.toSet().length, 2);
    });
  });

  group('recalculation cascade', () {
    test('editing an early grade changes the CGPA and reports the delta', () {
      final original = [
        _s('s1', 100, SemesterTerm.first, [_r('A101', 3, 'C')]),
        _s('s2', 100, SemesterTerm.second,
            [_r('B101', 3, 'A', semesterId: 's2')]),
      ];

      final before =
          CgpaEngine.computeStanding(semesters: original, scheme: scheme);
      expect(before.cgpa, 4.00);

      // Correct the 100L first-semester grade from C to A.
      final corrected = [
        _s('s1', 100, SemesterTerm.first, [_r('A101', 3, 'A')]),
        _s('s2', 100, SemesterTerm.second,
            [_r('B101', 3, 'A', semesterId: 's2')]),
      ];

      final result = CgpaEngine.recalculate(
        semesters: corrected,
        scheme: scheme,
        previous: before,
      );

      expect(result.updated.cgpa, 5.00);
      expect(result.cgpaDelta, 1.00);
      expect(result.improved, isTrue);
      expect(result.classificationChanged, isTrue);
    });
  });

  group('projection solver', () {
    // A student with 3.78 over 80 credits, four semesters left.
    AcademicStanding standingAt(double cgpa, int credits) => AcademicStanding(
          cgpa: cgpa,
          totalQualityPoints: cgpa * credits,
          totalCreditUnits: credits,
          totalCreditsPassed: credits,
          classification: scheme.classify(cgpa),
          semesters: [
            SemesterComputation(
              semesterId: 's1',
              level: 100,
              term: SemesterTerm.first,
              session: '2021/2022',
              qualityPoints: 4.31 * 20,
              creditUnits: 20,
              creditsPassed: 20,
              gpa: 4.31,
            ),
          ],
        );

    test('computes the required average correctly', () {
      final p = ProjectionSolver.solveForTarget(
        standing: standingAt(3.78, 80),
        scheme: scheme,
        targetCgpa: 4.50,
        targetLabel: 'First Class',
        semestersRemaining: 4,
      );

      // (4.50*160 - 302.4)/80 = (720 - 302.4)/80 = 5.22 -> above the 5.0 max
      expect(p.requiredAverage, closeTo(5.22, 0.01));
      expect(p.feasibility, Feasibility.unreachable);
      expect(p.isReachable, isFalse);
    });

    test('an unreachable target still offers a nearest achievable band', () {
      final p = ProjectionSolver.solveForTarget(
        standing: standingAt(3.10, 100),
        scheme: scheme,
        targetCgpa: 4.50,
        targetLabel: 'First Class',
        semestersRemaining: 2,
      );

      expect(p.feasibility, Feasibility.unreachable);
      expect(p.nearestAchievable, isNotNull);
      // Never leave the student with nothing to aim at.
      expect(p.nearestAchievable!.minCgpa, lessThan(4.50));
    });

    test('flags a target that exceeds the student personal best', () {
      final p = ProjectionSolver.solveForTarget(
        standing: standingAt(4.20, 80),
        scheme: scheme,
        targetCgpa: 4.50,
        semestersRemaining: 4,
      );

      // Required 4.80 exceeds the 4.31 personal best.
      expect(p.requiredAverage, closeTo(4.80, 0.01));
      expect(p.feasibility, Feasibility.demanding);
    });

    test('an already-secured target is reported as such', () {
      final p = ProjectionSolver.solveForTarget(
        standing: standingAt(4.70, 80),
        scheme: scheme,
        targetCgpa: 3.50,
        semestersRemaining: 2,
      );

      expect(p.feasibility, Feasibility.secured);
    });

    test('final-year student with no credits left gets a definitive answer',
        () {
      final p = ProjectionSolver.solveForTarget(
        standing: standingAt(3.20, 160),
        scheme: scheme,
        targetCgpa: 4.50,
        semestersRemaining: 0,
      );

      expect(p.requiredAverage, isNull);
      expect(p.feasibility, Feasibility.unreachable);
      expect(p.ceilingCgpa, 3.20);
    });

    test('forward simulation projects correctly', () {
      final f = ProjectionSolver.simulate(
        standing: standingAt(3.78, 80),
        scheme: scheme,
        assumedGpa: 4.50,
        semestersRemaining: 4,
      );

      // (302.4 + 4.5*80)/160 = 662.4/160 = 4.14
      expect(f.projectedCgpa, closeTo(4.14, 0.01));
      expect(f.projectedClassification?.shortLabel, '2:1');
      expect(f.deltaFromCurrent, closeTo(0.36, 0.01));
    });

    test('advisor payload contains only computed facts', () {
      final payload = ProjectionSolver.solveForTarget(
        standing: standingAt(3.78, 80),
        scheme: scheme,
        targetCgpa: 4.50,
        semestersRemaining: 4,
      ).toAdvisorPayload();

      // The AI receives these. It never sees raw grades to do maths on.
      expect(payload['required_average_gpa'], isNotNull);
      expect(payload['feasibility'], isA<String>());
      expect(payload['personal_best_semester_gpa'], isNotNull);
      expect(payload.containsKey('is_reachable'), isTrue);
    });
  });
}

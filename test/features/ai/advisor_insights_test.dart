import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/seed/nigerian_institutions.dart';
import 'package:perform_plus/domain/engine/cgpa_engine.dart';
import 'package:perform_plus/domain/engine/projection_solver.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/features/ai/services/advisor_insights.dart';

final _scheme = defaultSchemes['futo']!;

SemesterComputation _comp({
  required String id,
  required double gpa,
  int creditUnits = 20,
  int level = 100,
  SemesterTerm term = SemesterTerm.first,
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
    );

void main() {
  test('goal pace uses the solved required average, not the band minimum threshold', () {
    // cgpa 2.0 (100 credits earned), targeting Second Class Lower (min
    // 2.40) with 4 semesters (80 credits) remaining: solveForTarget's
    // required average works out well above the 2.40 band floor.
    final standing = AcademicStanding(
      cgpa: 2.0,
      totalQualityPoints: 200,
      totalCreditUnits: 100,
      totalCreditsPassed: 100,
      classification: _scheme.classify(2.0),
      semesters: [_comp(id: 's1', gpa: 2.0, creditUnits: 100)],
    );
    final band = _scheme.classifications.firstWhere((b) => b.shortLabel == '2:2');
    final projection = ProjectionSolver.solveForTarget(
      standing: standing,
      scheme: _scheme,
      targetCgpa: band.minCgpa,
      targetLabel: band.label,
      semestersRemaining: 4,
    );

    final state = buildAdvisorState(
      standing: standing,
      scheme: _scheme,
      rawSemesters: const [],
      goalBand: band,
      goalProjection: projection,
      profile: null,
      semestersRemaining: 0,
    );

    final goalPace = state.insights.first;
    expect(goalPace.kind, InsightKind.goalPace);
    expect(projection.requiredAverage, isNotNull);
    expect(goalPace.body, contains(projection.requiredAverage!.toStringAsFixed(2)));
    // 2.40 is the classification threshold, never the number shown.
    expect(goalPace.body, isNot(contains('2.40')));
  });

  group('trend card wording follows the sign of recentTrend', () {
    AdvisorState stateWith(double sem1Gpa, double sem2Gpa) {
      final standing = AcademicStanding(
        cgpa: 3.0,
        totalQualityPoints: 300,
        totalCreditUnits: 100,
        totalCreditsPassed: 100,
        classification: _scheme.classify(3.0),
        semesters: [
          _comp(id: 's1', gpa: sem1Gpa),
          _comp(id: 's2', gpa: sem2Gpa, term: SemesterTerm.second),
        ],
      );
      return buildAdvisorState(
        standing: standing,
        scheme: _scheme,
        rawSemesters: const [],
        goalBand: null,
        goalProjection: null,
        profile: null,
        semestersRemaining: 0,
      );
    }

    test('rising >= 0.05 says climbing', () {
      final trend = stateWith(3.00, 3.50).insights.firstWhere((i) => i.kind == InsightKind.trend);
      expect(trend.title, 'Your CGPA is climbing');
      expect(trend.trendDirection, TrendDirection.rising);
      expect(trend.body, contains('Up'));
    });

    test('falling <= -0.05 says slipped', () {
      final trend = stateWith(3.50, 3.20).insights.firstWhere((i) => i.kind == InsightKind.trend);
      expect(trend.title, 'Your CGPA has slipped');
      expect(trend.trendDirection, TrendDirection.falling);
      expect(trend.body, contains('Down'));
    });

    test('within the 0.05 deadband says steady', () {
      final trend = stateWith(3.00, 3.02).insights.firstWhere((i) => i.kind == InsightKind.trend);
      expect(trend.title, 'Your CGPA is steady');
      expect(trend.trendDirection, TrendDirection.steady);
      expect(trend.body, contains('Within'));
    });
  });

  test('fewer than two semesters shows only the insufficient-data card', () {
    final standing = AcademicStanding(
      cgpa: 3.0,
      totalQualityPoints: 60,
      totalCreditUnits: 20,
      totalCreditsPassed: 20,
      classification: _scheme.classify(3.0),
      semesters: [_comp(id: 's1', gpa: 3.0)],
    );

    final state = buildAdvisorState(
      standing: standing,
      scheme: _scheme,
      rawSemesters: const [],
      goalBand: null,
      goalProjection: null,
      profile: null,
      semestersRemaining: 0,
    );

    expect(state.insights, hasLength(1));
    expect(state.insights.single.kind, InsightKind.insufficientData);
  });

  test('a CGPA below the scheme\'s lowest floor triggers the critical standing state', () {
    // FUTO's lowest band (Pass) starts at 1.00.
    final standing = AcademicStanding(
      cgpa: 0.80,
      totalQualityPoints: 16,
      totalCreditUnits: 20,
      totalCreditsPassed: 5,
      classification: null,
      semesters: [_comp(id: 's1', gpa: 0.80)],
    );

    final state = buildAdvisorState(
      standing: standing,
      scheme: _scheme,
      rawSemesters: const [],
      goalBand: null,
      goalProjection: null,
      profile: null,
      semestersRemaining: 2,
    );

    expect(state.isCritical, isTrue);
    expect(state.critical!.cgpa, 0.80);
    expect(state.critical!.lowestBand.shortLabel, 'Pass');
    expect(state.critical!.lowestBand.minCgpa, 1.00);
  });

  test('the critical state suppresses every card except carryovers', () {
    final now = DateTime(2026, 1, 1);
    CourseResult failing(String id) => CourseResult(
          id: id,
          semesterId: 's1',
          courseCode: 'MTH101',
          creditUnit: 3,
          grade: 'F',
          createdAt: now,
          updatedAt: now,
        );
    final semester = Semester(
      id: 's1',
      profileId: 'p1',
      session: '2024/2025',
      term: SemesterTerm.first,
      level: 100,
      results: [failing('r1')],
      createdAt: now,
      updatedAt: now,
    );

    final standing = AcademicStanding(
      cgpa: 0.50,
      totalQualityPoints: 1.5,
      totalCreditUnits: 3,
      totalCreditsPassed: 0,
      classification: null,
      semesters: [_comp(id: 's1', gpa: 0.50, creditUnits: 3)],
    );
    final goalBand = _scheme.classifications.firstWhere((b) => b.shortLabel == 'First Class');
    final goalProjection = ProjectionSolver.solveForTarget(
      standing: standing,
      scheme: _scheme,
      targetCgpa: goalBand.minCgpa,
      targetLabel: goalBand.label,
      semestersRemaining: 6,
    );

    final state = buildAdvisorState(
      standing: standing,
      scheme: _scheme,
      rawSemesters: [semester],
      goalBand: goalBand,
      goalProjection: goalProjection,
      profile: null,
      semestersRemaining: 2,
    );

    expect(state.isCritical, isTrue);
    expect(state.insights, hasLength(1));
    expect(state.insights.single.kind, InsightKind.carryovers);
    // A First Class goal pace card underneath a critical-standing card
    // would be absurd -- it must not be present at all.
    expect(state.insights.any((i) => i.kind == InsightKind.goalPace), isFalse);
  });
}

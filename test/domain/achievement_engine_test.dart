import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/domain/engine/achievement_engine.dart';
import 'package:perform_plus/domain/engine/cgpa_engine.dart';
import 'package:perform_plus/domain/models/achievement.dart';
import 'package:perform_plus/domain/models/course_result.dart';

SemesterComputation _comp({required String id, required double gpa, int creditUnits = 20}) =>
    SemesterComputation(
      semesterId: id,
      level: 100,
      term: SemesterTerm.first,
      session: '2024/2025',
      qualityPoints: gpa * creditUnits,
      creditUnits: creditUnits,
      creditsPassed: creditUnits,
      gpa: gpa,
    );

const _emptyStanding = AcademicStanding(
  cgpa: 0,
  totalQualityPoints: 0,
  totalCreditUnits: 0,
  totalCreditsPassed: 0,
);

void main() {
  group('firstSteps -- any data at all', () {
    test('not earned with no data on record', () {
      expect(evaluateEarnedBadges(standing: _emptyStanding, currentStreak: 0), isNot(contains(BadgeId.firstSteps)));
    });

    test('earned the moment a single semester exists', () {
      final standing = AcademicStanding(
        cgpa: 4.0,
        totalQualityPoints: 80,
        totalCreditUnits: 20,
        totalCreditsPassed: 20,
        semesters: [_comp(id: 's1', gpa: 4.0)],
      );
      expect(evaluateEarnedBadges(standing: standing, currentStreak: 0), contains(BadgeId.firstSteps));
    });
  });

  group('consistentLearner -- 7-day streak threshold', () {
    test('a 6-day streak does not qualify', () {
      expect(
        evaluateEarnedBadges(standing: _emptyStanding, currentStreak: 6),
        isNot(contains(BadgeId.consistentLearner)),
      );
    });

    test('a 7-day streak qualifies', () {
      expect(
        evaluateEarnedBadges(standing: _emptyStanding, currentStreak: 7),
        contains(BadgeId.consistentLearner),
      );
    });
  });

  group('topPerformer -- a semester GPA strictly above 4.0', () {
    test('exactly 4.0 does not qualify', () {
      final standing = AcademicStanding(
        cgpa: 4.0,
        totalQualityPoints: 80,
        totalCreditUnits: 20,
        totalCreditsPassed: 20,
        semesters: [_comp(id: 's1', gpa: 4.0)],
      );
      expect(evaluateEarnedBadges(standing: standing, currentStreak: 0), isNot(contains(BadgeId.topPerformer)));
    });

    test('4.01 qualifies', () {
      final standing = AcademicStanding(
        cgpa: 4.01,
        totalQualityPoints: 80.2,
        totalCreditUnits: 20,
        totalCreditsPassed: 20,
        semesters: [_comp(id: 's1', gpa: 4.01)],
      );
      expect(evaluateEarnedBadges(standing: standing, currentStreak: 0), contains(BadgeId.topPerformer));
    });

    test('a semester with zero credit units is not considered, even at a high GPA', () {
      final standing = AcademicStanding(
        cgpa: 0,
        totalQualityPoints: 0,
        totalCreditUnits: 0,
        totalCreditsPassed: 0,
        semesters: [_comp(id: 's1', gpa: 5.0, creditUnits: 0)],
      );
      expect(evaluateEarnedBadges(standing: standing, currentStreak: 0), isNot(contains(BadgeId.topPerformer)));
    });
  });

  group('improvementKing -- a rise of 0.5 or more between consecutive semesters', () {
    test('a rise of 0.49 does not qualify', () {
      final standing = AcademicStanding(
        cgpa: 3.5,
        totalQualityPoints: 140,
        totalCreditUnits: 40,
        totalCreditsPassed: 40,
        semesters: [_comp(id: 's1', gpa: 3.0), _comp(id: 's2', gpa: 3.49)],
      );
      expect(evaluateEarnedBadges(standing: standing, currentStreak: 0), isNot(contains(BadgeId.improvementKing)));
    });

    test('a rise of exactly 0.5 qualifies', () {
      final standing = AcademicStanding(
        cgpa: 3.5,
        totalQualityPoints: 140,
        totalCreditUnits: 40,
        totalCreditsPassed: 40,
        semesters: [_comp(id: 's1', gpa: 3.0), _comp(id: 's2', gpa: 3.5)],
      );
      expect(evaluateEarnedBadges(standing: standing, currentStreak: 0), contains(BadgeId.improvementKing));
    });

    test('a drop of the same magnitude does not qualify', () {
      final standing = AcademicStanding(
        cgpa: 3.5,
        totalQualityPoints: 140,
        totalCreditUnits: 40,
        totalCreditsPassed: 40,
        semesters: [_comp(id: 's1', gpa: 3.5), _comp(id: 's2', gpa: 3.0)],
      );
      expect(evaluateEarnedBadges(standing: standing, currentStreak: 0), isNot(contains(BadgeId.improvementKing)));
    });
  });

  test('badges are additive, not mutually exclusive', () {
    final standing = AcademicStanding(
      cgpa: 4.5,
      totalQualityPoints: 180,
      totalCreditUnits: 40,
      totalCreditsPassed: 40,
      semesters: [_comp(id: 's1', gpa: 4.0), _comp(id: 's2', gpa: 4.6)],
    );
    final earned = evaluateEarnedBadges(standing: standing, currentStreak: 7);

    expect(earned, {BadgeId.firstSteps, BadgeId.consistentLearner, BadgeId.topPerformer, BadgeId.improvementKing});
  });
}

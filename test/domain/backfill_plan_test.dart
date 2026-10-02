import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/domain/models/backfill_plan.dart';
import 'package:perform_plus/domain/models/course_result.dart';

final _now = DateTime(2026, 1, 1);

Semester _semester(int level, SemesterTerm term) => Semester(
      id: '$level-${term.name}',
      profileId: 'p1',
      session: '2024/2025',
      term: term,
      level: level,
      createdAt: _now,
      updatedAt: _now,
    );

void main() {
  group('expectedSemesterKeys', () {
    test('a 300L student with only the Act 1 semester expects 5, not 12',
        () {
      final expected = expectedSemesterKeys(
        currentLevel: 300,
        existingSemesters: [_semester(300, SemesterTerm.first)],
      );

      expect(expected, hasLength(5));
      expect(expected, isNot(contains(const SemesterKey(300, SemesterTerm.second))));
      // Never a level the student hasn't reached.
      expect(expected.any((k) => k.level >= 400), isFalse);
      expect(
        expected,
        containsAll(const [
          SemesterKey(100, SemesterTerm.first),
          SemesterKey(100, SemesterTerm.second),
          SemesterKey(200, SemesterTerm.first),
          SemesterKey(200, SemesterTerm.second),
          SemesterKey(300, SemesterTerm.first),
        ]),
      );
    });

    test(
        'a 300L student whose Act 1 semester is the second term expects both '
        "300L semesters — it's already concluded", () {
      final expected = expectedSemesterKeys(
        currentLevel: 300,
        existingSemesters: [_semester(300, SemesterTerm.second)],
      );

      expect(expected, hasLength(6));
      expect(expected, contains(const SemesterKey(300, SemesterTerm.second)));
    });

    test('a fresh 100L student with just their Act 1 semester expects only it',
        () {
      final expected = expectedSemesterKeys(
        currentLevel: 100,
        existingSemesters: [_semester(100, SemesterTerm.first)],
      );

      expect(expected, [const SemesterKey(100, SemesterTerm.first)]);
    });
  });

  group('countAdded', () {
    test('counts only expected slots that already have a matching semester',
        () {
      final expected = expectedSemesterKeys(
        currentLevel: 300,
        existingSemesters: [_semester(300, SemesterTerm.first)],
      );
      final existing = [
        _semester(100, SemesterTerm.first),
        _semester(300, SemesterTerm.first),
      ];

      expect(countAdded(expected, existing), 2);
    });

    test('a first-year student with their one semester is fully added', () {
      final expected = expectedSemesterKeys(
        currentLevel: 100,
        existingSemesters: [_semester(100, SemesterTerm.first)],
      );
      final existing = [_semester(100, SemesterTerm.first)];

      expect(countAdded(expected, existing), expected.length);
    });
  });
}

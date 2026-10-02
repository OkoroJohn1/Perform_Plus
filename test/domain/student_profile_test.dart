import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/domain/models/student_profile.dart';

void main() {
  group('remainingSemestersFromLevel', () {
    test('a 5-year programme, 300L, 2 levels already behind', () {
      // 2021 -> 2026 is 10 total semesters; 100L and 200L (4 semesters) are
      // already behind a 300L student, leaving 6.
      final remaining = remainingSemestersFromLevel(
        currentLevel: 300,
        entryYear: 2021,
        expectedGraduationYear: 2026,
      );
      expect(remaining, 6);
    });

    test('a fresh 100L student has every semester of the programme left', () {
      final remaining = remainingSemestersFromLevel(
        currentLevel: 100,
        entryYear: 2024,
        expectedGraduationYear: 2028,
      );
      expect(remaining, 8);
    });

    test('a final-level student on a 6-year programme has its own 2 semesters left',
        () {
      // 600L implies at least a 6-year programme (100L..600L) — 2021 to
      // 2027, not 2026, or the level itself wouldn't exist yet.
      final remaining = remainingSemestersFromLevel(
        currentLevel: 600,
        entryYear: 2021,
        expectedGraduationYear: 2027,
      );
      expect(remaining, 2);
    });

    test('floors at zero rather than going negative for a nonsensical span',
        () {
      final remaining = remainingSemestersFromLevel(
        currentLevel: 600,
        entryYear: 2024,
        expectedGraduationYear: 2024,
      );
      expect(remaining, 0);
    });
  });
}

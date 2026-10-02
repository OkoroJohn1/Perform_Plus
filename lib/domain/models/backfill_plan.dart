/// What "add your previous semesters" actually means for THIS student —
/// pure Dart, no Flutter imports (see `academic_record_repository.dart`'s
/// purity rationale).
///
/// The naive version of this screen shows six fixed levels (100-600)
/// regardless of the student's actual level, which shows semesters that
/// haven't happened yet to anyone below 600L. The expected set here is
/// derived from the profile instead: every level up to the student's
/// current one (two semesters each), plus however much of the CURRENT
/// level is already known — never more.
library;

import 'course_result.dart';

/// One (level, term) slot the backfill screen can show a row for.
class SemesterKey {
  final int level;
  final SemesterTerm term;

  const SemesterKey(this.level, this.term);

  @override
  bool operator ==(Object other) =>
      other is SemesterKey && other.level == level && other.term == term;

  @override
  int get hashCode => Object.hash(level, term);
}

/// The full set of (level, term) slots this student could ever backfill,
/// given where they are right now.
///
/// "Where they are right now" for the CURRENT level's term coverage is
/// read off [existingSemesters] rather than asked for separately: a
/// semester at `(currentLevel, second)` already existing is exactly what
/// tells us the student has concluded that term, and a corresponding
/// `first` should already exist too (added during Act 1) — see
/// `backfill_screen.dart` for how the two combine into the on-entry skip
/// check. Never returns a level above [currentLevel].
List<SemesterKey> expectedSemesterKeys({
  required int currentLevel,
  required List<Semester> existingSemesters,
}) {
  final currentLevelHasSecondTerm = existingSemesters
      .any((s) => s.level == currentLevel && s.term == SemesterTerm.second);

  final keys = <SemesterKey>[];
  for (var level = 100; level < currentLevel; level += 100) {
    keys.add(SemesterKey(level, SemesterTerm.first));
    keys.add(SemesterKey(level, SemesterTerm.second));
  }
  keys.add(SemesterKey(currentLevel, SemesterTerm.first));
  if (currentLevelHasSecondTerm) {
    keys.add(SemesterKey(currentLevel, SemesterTerm.second));
  }
  return keys;
}

/// Of [expected], how many already have a matching semester.
int countAdded(List<SemesterKey> expected, List<Semester> existingSemesters) {
  return expected
      .where((key) => existingSemesters
          .any((s) => s.level == key.level && s.term == key.term))
      .length;
}

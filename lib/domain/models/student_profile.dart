/// Student profile. Pure Dart — no Flutter imports.
library;

import '../../core/constants/app_constants.dart';

class StudentProfile {
  final String fullName;
  final String regNumber;
  final String department;
  final int currentLevel;
  final int entryYear;
  final int expectedGraduationYear;

  /// Optional — most institutions' faculty lists aren't catalogued yet
  /// (see `data/seed/nigerian_institutions.dart`), so this stays free-form
  /// and nullable rather than forcing a value out of nothing.
  final String? faculty;

  /// Local file path to the (optional) profile photo — never a URL. See
  /// `profile_photo_store.dart` for how it gets there; a remote copy is a
  /// separate concern (Supabase Storage) synced only when a session exists.
  final String? photoPath;

  const StudentProfile({
    required this.fullName,
    required this.regNumber,
    required this.department,
    required this.currentLevel,
    required this.entryYear,
    required this.expectedGraduationYear,
    this.faculty,
    this.photoPath,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  StudentProfile copyWith({
    String? fullName,
    String? regNumber,
    String? department,
    int? currentLevel,
    int? entryYear,
    int? expectedGraduationYear,
    String? faculty,
    String? photoPath,
  }) =>
      StudentProfile(
        fullName: fullName ?? this.fullName,
        regNumber: regNumber ?? this.regNumber,
        department: department ?? this.department,
        currentLevel: currentLevel ?? this.currentLevel,
        entryYear: entryYear ?? this.entryYear,
        expectedGraduationYear:
            expectedGraduationYear ?? this.expectedGraduationYear,
        faculty: faculty ?? this.faculty,
        photoPath: photoPath ?? this.photoPath,
      );
}

/// Semesters left before expected graduation, computed from the profile's
/// own years — never invented. Floors at zero for a profile whose expected
/// graduation year has already passed.
int semestersRemainingFor(StudentProfile profile) {
  final currentYear = DateTime.now().year;
  final yearsRemaining = profile.expectedGraduationYear - currentYear;
  if (yearsRemaining <= 0) return 0;
  return yearsRemaining * AppConstants.semestersPerLevel;
}

/// The profile-setup form's live "That's N semesters remaining" sanity
/// check — distinct from [semestersRemainingFor], which answers "as of
/// today" for the goal/roadmap engine. This one answers "given the
/// programme implied by these three fields", so a student can catch a
/// mistyped year before it silently distorts every later projection.
///
/// Total programme semesters = (gradYear - entryYear) * 2. Semesters
/// already behind the student = levels completed before [currentLevel]
/// (0 for 100L, 1 for 200L, ... ) * 2. Never negative — a nonsensical
/// input (e.g. graduation before entry) floors at zero rather than
/// returning a confusing negative count; the form surfaces that case as
/// a validation warning instead, not through this number.
int remainingSemestersFromLevel({
  required int currentLevel,
  required int entryYear,
  required int expectedGraduationYear,
}) {
  final totalSemesters =
      (expectedGraduationYear - entryYear) * AppConstants.semestersPerLevel;
  final levelsCompleted = ((currentLevel - 100) / 100).floor();
  final semestersCompleted = levelsCompleted * AppConstants.semestersPerLevel;
  final remaining = totalSemesters - semestersCompleted;
  return remaining < 0 ? 0 : remaining;
}

/// Student profile — kept separate from [AuthState], which is auth-only.
///
/// TODO(v1): replace with a Drift/Supabase-backed repository once local
/// storage lands. Until then this is in-memory and resets on app restart,
/// same posture as every other provider in the app pre-Drift.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';

class StudentProfile {
  final String fullName;
  final String regNumber;
  final String department;
  final int currentLevel;
  final int entryYear;
  final int expectedGraduationYear;

  const StudentProfile({
    required this.fullName,
    required this.regNumber,
    required this.department,
    required this.currentLevel,
    required this.entryYear,
    required this.expectedGraduationYear,
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
  }) =>
      StudentProfile(
        fullName: fullName ?? this.fullName,
        regNumber: regNumber ?? this.regNumber,
        department: department ?? this.department,
        currentLevel: currentLevel ?? this.currentLevel,
        entryYear: entryYear ?? this.entryYear,
        expectedGraduationYear:
            expectedGraduationYear ?? this.expectedGraduationYear,
      );
}

final studentProfileProvider = StateProvider<StudentProfile?>((ref) => null);

/// Semesters left before expected graduation, computed from the profile's
/// own years — never invented. Floors at zero for a profile whose expected
/// graduation year has already passed.
int semestersRemainingFor(StudentProfile profile) {
  final currentYear = DateTime.now().year;
  final yearsRemaining = profile.expectedGraduationYear - currentYear;
  if (yearsRemaining <= 0) return 0;
  return yearsRemaining * AppConstants.semestersPerLevel;
}

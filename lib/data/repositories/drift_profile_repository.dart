/// Drift-backed [ProfileRepository]. Hardcodes the single local profile
/// row key internally — it never leaks into the interface.
library;

import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/student_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../local/app_database.dart';
import '../local/daos/profile_dao.dart';

class DriftProfileRepository implements ProfileRepository {
  final ProfileDao _dao;

  DriftProfileRepository(this._dao);

  @override
  Future<StudentProfile?> loadProfile() async {
    final row = await _dao.getProfile(AppConstants.localProfileId);
    if (row == null) return null;
    return StudentProfile(
      fullName: row.fullName,
      regNumber: row.regNumber,
      department: row.department,
      currentLevel: row.currentLevel,
      entryYear: row.entryYear,
      expectedGraduationYear: row.expectedGraduationYear,
      faculty: row.faculty,
      photoPath: row.photoPath,
    );
  }

  @override
  Future<void> saveProfile(StudentProfile profile) => _dao.upsertProfile(
        ProfilesCompanion.insert(
          id: AppConstants.localProfileId,
          fullName: profile.fullName,
          regNumber: profile.regNumber,
          department: profile.department,
          currentLevel: profile.currentLevel,
          entryYear: profile.entryYear,
          expectedGraduationYear: profile.expectedGraduationYear,
          faculty: Value(profile.faculty),
          photoPath: Value(profile.photoPath),
          updatedAt: DateTime.now(),
        ),
      );
}

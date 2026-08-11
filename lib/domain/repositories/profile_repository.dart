/// Abstract interface only — see `academic_record_repository.dart` for the
/// purity rationale.
library;

import '../models/student_profile.dart';

abstract class ProfileRepository {
  Future<StudentProfile?> loadProfile();
  Future<void> saveProfile(StudentProfile profile);
}

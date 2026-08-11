/// Abstract interface only — no `package:flutter`, `package:flutter_riverpod`
/// or `package:drift` imports. `dart:async` (core Dart) is fine: a
/// repository interface describing I/O-backed operations needs `Future`
/// return types to be meaningful at all.
///
/// `lib/data/repositories/drift_academic_record_repository.dart` implements
/// this today. A future remote-sync implementation can satisfy the same
/// contract without any UI or provider changes.
library;

import '../models/course_result.dart';

abstract class AcademicRecordRepository {
  Future<List<Semester>> loadSemesters();
  Future<void> addSemester(Semester semester);
  Future<void> updateSemester(Semester semester);
  Future<void> removeSemester(String id);
}

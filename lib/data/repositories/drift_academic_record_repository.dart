/// Drift-backed [AcademicRecordRepository]. Composes [SemesterDao] and
/// [CourseResultDao] to reconstruct/decompose full [Semester] objects —
/// the DAOs themselves stay single-table.
library;

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/course_result.dart';
import '../../domain/repositories/academic_record_repository.dart';
import '../local/app_database.dart';
import '../local/daos/course_result_dao.dart';
import '../local/daos/semester_dao.dart';

class DriftAcademicRecordRepository implements AcademicRecordRepository {
  final SemesterDao _semesterDao;
  final CourseResultDao _courseResultDao;

  DriftAcademicRecordRepository(this._semesterDao, this._courseResultDao);

  @override
  Future<List<Semester>> loadSemesters() async {
    final semesterRows =
        await _semesterDao.getSemestersForProfile(AppConstants.localProfileId);
    if (semesterRows.isEmpty) return const [];

    final ids = semesterRows.map((s) => s.id).toList();
    final resultRows = await _courseResultDao.getResultsForSemesters(ids);
    final resultsBySemester = groupBy(resultRows, (CourseResultRow r) => r.semesterId);

    return semesterRows
        .map((s) => _toDomain(s, resultsBySemester[s.id] ?? const []))
        .toList();
  }

  @override
  Future<void> addSemester(Semester semester) => _upsert(semester);

  @override
  Future<void> updateSemester(Semester semester) => _upsert(semester);

  @override
  Future<void> removeSemester(String id) async {
    await _courseResultDao.deleteResultsForSemester(id);
    await _semesterDao.deleteSemester(id);
  }

  Future<void> _upsert(Semester semester) async {
    await _semesterDao.upsertSemester(
      SemestersCompanion.insert(
        id: semester.id,
        profileId: semester.profileId,
        session: semester.session,
        term: semester.term,
        level: semester.level,
        createdAt: semester.createdAt,
        updatedAt: semester.updatedAt,
      ),
    );
    // Results are replaced wholesale rather than diffed — a semester's row
    // count is small (a handful of courses) and the caller always has the
    // full, current list.
    await _courseResultDao.deleteResultsForSemester(semester.id);
    if (semester.results.isNotEmpty) {
      await _courseResultDao.upsertResults(
        semester.results.map(_resultToCompanion).toList(),
      );
    }
  }

  Semester _toDomain(SemesterRow row, List<CourseResultRow> results) => Semester(
        id: row.id,
        profileId: row.profileId,
        session: row.session,
        term: row.term,
        level: row.level,
        results: results.map(_resultToDomain).toList(),
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  CourseResult _resultToDomain(CourseResultRow row) => CourseResult(
        id: row.id,
        semesterId: row.semesterId,
        courseCode: row.courseCode,
        courseTitle: row.courseTitle,
        creditUnit: row.creditUnit,
        grade: row.grade,
        score: row.score,
        attempt: row.attempt,
        supersedesResultId: row.supersedesResultId,
        source: row.source,
        extractionConfidence: row.extractionConfidence,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  CourseResultsCompanion _resultToCompanion(CourseResult r) =>
      CourseResultsCompanion.insert(
        id: r.id,
        semesterId: r.semesterId,
        courseCode: r.courseCode,
        courseTitle: Value(r.courseTitle),
        creditUnit: r.creditUnit,
        grade: r.grade,
        score: Value(r.score),
        attempt: Value(r.attempt),
        supersedesResultId: Value(r.supersedesResultId),
        source: r.source,
        extractionConfidence: Value(r.extractionConfidence),
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );
}

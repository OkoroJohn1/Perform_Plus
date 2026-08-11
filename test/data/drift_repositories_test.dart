import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/drift_academic_record_repository.dart';
import 'package:perform_plus/data/repositories/drift_goal_repository.dart';
import 'package:perform_plus/data/repositories/drift_grading_scheme_repository.dart';
import 'package:perform_plus/data/repositories/drift_profile_repository.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/domain/models/goal_target.dart';
import 'package:perform_plus/domain/models/grading_scheme.dart';
import 'package:perform_plus/domain/models/student_profile.dart';

final _now = DateTime(2026, 1, 1);

CourseResult _result(String code, {String semesterId = 's1'}) => CourseResult(
      id: '$semesterId-$code',
      semesterId: semesterId,
      courseCode: code,
      creditUnit: 3,
      grade: 'A',
      createdAt: _now,
      updatedAt: _now,
    );

Semester _semester(String id, {List<CourseResult>? results}) => Semester(
      id: id,
      profileId: 'local-profile',
      session: '2024/2025',
      term: SemesterTerm.first,
      level: 100,
      results: results ?? [_result('CSC101', semesterId: id)],
      createdAt: _now,
      updatedAt: _now,
    );

GradingScheme _scheme() => GradingScheme(
      id: 'futo_v1',
      institutionId: 'futo',
      name: 'FUTO 5.0 Scale',
      version: 1,
      effectiveFrom: DateTime(2015),
      maxPoint: 5.0,
      grades: const [
        GradeDefinition(letter: 'A', point: 5.0, minScore: 70, maxScore: 100),
        GradeDefinition(letter: 'F', point: 0.0, minScore: 0, maxScore: 39),
      ],
      classifications: const [
        ClassificationBand(
          label: 'First Class Honours',
          shortLabel: 'First Class',
          minCgpa: 4.50,
          maxCgpa: 5.00,
        ),
      ],
      repeatPolicy: RepeatPolicy.countBothAttempts,
    );

void main() {
  group('DriftAcademicRecordRepository', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('starts empty', () async {
      final repo = DriftAcademicRecordRepository(db.semesterDao, db.courseResultDao);
      expect(await repo.loadSemesters(), isEmpty);
    });

    test('add/load round-trip preserves nested course results', () async {
      final repo = DriftAcademicRecordRepository(db.semesterDao, db.courseResultDao);
      final semester = _semester('s1', results: [
        _result('CSC101', semesterId: 's1'),
        _result('MTH101', semesterId: 's1'),
      ]);

      await repo.addSemester(semester);
      final loaded = await repo.loadSemesters();

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 's1');
      expect(loaded.single.results.map((r) => r.courseCode), containsAll(['CSC101', 'MTH101']));
    });

    test('update replaces the results wholesale', () async {
      final repo = DriftAcademicRecordRepository(db.semesterDao, db.courseResultDao);
      await repo.addSemester(_semester('s1'));

      final updated = _semester('s1', results: [_result('PHY101', semesterId: 's1')]);
      await repo.updateSemester(updated);

      final loaded = await repo.loadSemesters();
      expect(loaded.single.results, hasLength(1));
      expect(loaded.single.results.single.courseCode, 'PHY101');
    });

    test('remove deletes the semester and its results', () async {
      final repo = DriftAcademicRecordRepository(db.semesterDao, db.courseResultDao);
      await repo.addSemester(_semester('s1'));
      await repo.removeSemester('s1');

      expect(await repo.loadSemesters(), isEmpty);
    });

    test('a second repository instance sharing the connection sees prior writes', () async {
      final first = DriftAcademicRecordRepository(db.semesterDao, db.courseResultDao);
      await first.addSemester(_semester('s1'));

      // Simulates "restart": a fresh repository/DAO pair reading the same
      // live connection, proving the write actually persisted rather than
      // living only in the first repository's memory.
      final second = DriftAcademicRecordRepository(db.semesterDao, db.courseResultDao);
      final loaded = await second.loadSemesters();

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 's1');
    });
  });

  group('DriftProfileRepository', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('returns null when nothing saved yet', () async {
      final repo = DriftProfileRepository(db.profileDao);
      expect(await repo.loadProfile(), isNull);
    });

    test('save/load round-trip', () async {
      final repo = DriftProfileRepository(db.profileDao);
      const profile = StudentProfile(
        fullName: 'Ada Obi',
        regNumber: '21/ENG/12345',
        department: 'Computer Science',
        currentLevel: 300,
        entryYear: 2021,
        expectedGraduationYear: 2026,
      );

      await repo.saveProfile(profile);
      final loaded = await repo.loadProfile();

      expect(loaded?.fullName, 'Ada Obi');
      expect(loaded?.regNumber, '21/ENG/12345');
      expect(loaded?.entryYear, 2021);
    });

    test('saving a profile does not clobber an active scheme set separately', () async {
      final profileRepo = DriftProfileRepository(db.profileDao);
      final schemeRepo = DriftGradingSchemeRepository(db.gradingSchemeDao, db.profileDao);

      await schemeRepo.saveActiveScheme(_scheme());
      await profileRepo.saveProfile(const StudentProfile(
        fullName: 'Ada Obi',
        regNumber: '21/ENG/12345',
        department: 'Computer Science',
        currentLevel: 300,
        entryYear: 2021,
        expectedGraduationYear: 2026,
      ));

      final scheme = await schemeRepo.loadActiveScheme();
      expect(scheme?.id, 'futo_v1');
    });
  });

  group('DriftGoalRepository', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('returns null when no goal set', () async {
      final repo = DriftGoalRepository(db.goalDao);
      expect(await repo.loadGoal(), isNull);
    });

    test('save/load round-trip', () async {
      final repo = DriftGoalRepository(db.goalDao);
      const goal = GoalTarget(
        band: ClassificationBand(
          label: 'First Class Honours',
          shortLabel: 'First Class',
          minCgpa: 4.50,
          maxCgpa: 5.00,
        ),
        semestersRemaining: 4,
      );

      await repo.saveGoal(goal);
      final loaded = await repo.loadGoal();

      expect(loaded?.band.shortLabel, 'First Class');
      expect(loaded?.semestersRemaining, 4);
    });

    test('clear removes the goal', () async {
      final repo = DriftGoalRepository(db.goalDao);
      const goal = GoalTarget(
        band: ClassificationBand(
          label: 'First Class Honours',
          shortLabel: 'First Class',
          minCgpa: 4.50,
          maxCgpa: 5.00,
        ),
        semestersRemaining: 4,
      );
      await repo.saveGoal(goal);
      await repo.clearGoal();

      expect(await repo.loadGoal(), isNull);
    });
  });

  group('DriftGradingSchemeRepository', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('returns null when nothing saved yet', () async {
      final repo = DriftGradingSchemeRepository(db.gradingSchemeDao, db.profileDao);
      expect(await repo.loadActiveScheme(), isNull);
    });

    test('save/load round-trip preserves grades and classifications', () async {
      final repo = DriftGradingSchemeRepository(db.gradingSchemeDao, db.profileDao);

      await repo.saveActiveScheme(_scheme());
      final loaded = await repo.loadActiveScheme();

      expect(loaded?.id, 'futo_v1');
      expect(loaded?.grades.map((g) => g.letter), containsAll(['A', 'F']));
      expect(loaded?.classifications.single.shortLabel, 'First Class');
      expect(loaded?.repeatPolicy, RepeatPolicy.countBothAttempts);
    });

    test('creates a minimal profile row if none exists yet', () async {
      final schemeRepo = DriftGradingSchemeRepository(db.gradingSchemeDao, db.profileDao);
      final profileRepo = DriftProfileRepository(db.profileDao);

      expect(await profileRepo.loadProfile(), isNull);
      await schemeRepo.saveActiveScheme(_scheme());

      // The profile row now exists (even if blank) so the active-scheme
      // pointer has somewhere to live.
      final row = await db.profileDao.getProfile('local-profile');
      expect(row?.activeSchemeId, 'futo_v1');
    });

    test('saving a scheme after a profile exists does not clobber the profile', () async {
      final schemeRepo = DriftGradingSchemeRepository(db.gradingSchemeDao, db.profileDao);
      final profileRepo = DriftProfileRepository(db.profileDao);

      await profileRepo.saveProfile(const StudentProfile(
        fullName: 'Ada Obi',
        regNumber: '21/ENG/12345',
        department: 'Computer Science',
        currentLevel: 300,
        entryYear: 2021,
        expectedGraduationYear: 2026,
      ));

      // Every semester saved through AcademicRecordController re-saves the
      // active scheme alongside it (see academic_record_provider.dart's
      // `_persist`) — this must not blank the profile out again.
      await schemeRepo.saveActiveScheme(_scheme());

      final profile = await profileRepo.loadProfile();
      expect(profile?.fullName, 'Ada Obi');
      expect(profile?.regNumber, '21/ENG/12345');
      expect(profile?.entryYear, 2021);

      final scheme = await schemeRepo.loadActiveScheme();
      expect(scheme?.id, 'futo_v1');
    });
  });
}

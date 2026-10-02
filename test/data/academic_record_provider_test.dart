import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/academic_record_provider.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/domain/models/course_result.dart';

final _now = DateTime(2026, 1, 1);

Semester _semester(String id, int level, SemesterTerm term, String grade) =>
    Semester(
      id: id,
      profileId: 'local-profile',
      session: '2024/2025',
      term: term,
      level: level,
      results: [
        CourseResult(
          id: '$id-CSC101',
          semesterId: id,
          courseCode: 'CSC101',
          creditUnit: 3,
          grade: grade,
          createdAt: _now,
          updatedAt: _now,
        ),
      ],
      createdAt: _now,
      updatedAt: _now,
    );

void main() {
  test(
      'backfilling a 100L semester after a 200L one recalculates CGPA across '
      'the whole record, the cascade the backfill screen relies on',
      () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(
          AppDatabase.forTesting(NativeDatabase.memory()),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(academicRecordProvider.notifier);
    await notifier.ready;
    // The assertion below depends on FUTO's exact grade points — confirm
    // the default onboarding scheme is actually FUTO's rather than assume it.
    expect(container.read(academicRecordProvider).scheme.id, 'futo_v1');

    notifier.addSemester(_semester('s200', 200, SemesterTerm.first, 'A'));
    final beforeBackfill = container.read(standingProvider);
    expect(beforeBackfill.cgpa, 5.0);

    // Backfilling a 100L semester with a lower grade, after the 200L one
    // already existed, must change the cumulative CGPA — not just sit
    // alongside it unrecomputed. `computeStanding` recomputes from the
    // full semester list every time (see cgpa_engine.dart), so this only
    // proves the wiring: the notifier actually rebuilds `state` with both
    // semesters rather than losing or ignoring the earlier one.
    notifier.addSemester(_semester('s100', 100, SemesterTerm.first, 'C'));
    final afterBackfill = container.read(standingProvider);

    expect(afterBackfill.cgpa, isNot(beforeBackfill.cgpa));
    // (3 units * 5.0 + 3 units * 3.0) / 6 units = 4.0.
    expect(afterBackfill.cgpa, 4.0);
    expect(afterBackfill.semesters.map((s) => s.level).toList(), [100, 200]);

    // Let both semesters' fire-and-forget Drift writes settle before the
    // container (and its in-memory database) close in tearDown — disposing
    // mid-write throws from inside the pending write's microtask, which
    // otherwise fails this test with no attributable stack trace.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
}

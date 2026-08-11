/// The signed-in student's full academic record.
///
/// Backed by Drift (`lib/data/local`) via [AcademicRecordRepository] and
/// [GradingSchemeRepository] — writes persist across restarts, and the
/// constructor reloads persisted state so a student's results and scheme
/// selection survive closing the app.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/engine/cgpa_engine.dart';
import '../../domain/models/course_result.dart';
import '../../domain/models/grading_scheme.dart';
import '../../domain/repositories/academic_record_repository.dart';
import '../../domain/repositories/grading_scheme_repository.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import 'repository_providers.dart';

class AcademicRecord {
  final List<Semester> semesters;
  final GradingScheme scheme;

  const AcademicRecord({required this.semesters, required this.scheme});
}

class AcademicRecordController extends StateNotifier<AcademicRecord> {
  final AcademicRecordRepository? _repository;
  final GradingSchemeRepository? _schemeRepository;

  AcademicRecordController(
    Ref ref,
    AcademicRecordRepository repository,
    GradingSchemeRepository schemeRepository,
  )   : _repository = repository,
        _schemeRepository = schemeRepository,
        super(_seedFrom(ref.read(onboardingDraftProvider))) {
    ref.listen(onboardingDraftProvider, (previous, next) {
      // The draft's committed semester only ever appears once, right after
      // the Add Results screen commits it. Re-seeding on every draft change
      // would clobber Results CRUD done afterwards, so only fold it in the
      // first time.
      if (previous?.committed == null && next.committed != null) {
        addSemester(next.committed!);
      }
    });
    unawaited(_loadPersisted());
  }

  /// Fixed-state constructor for widget tests — bypasses the onboarding
  /// draft and Drift entirely so a test can hand it an exact [AcademicRecord].
  AcademicRecordController.seeded(super.record)
      : _repository = null,
        _schemeRepository = null;

  static AcademicRecord _seedFrom(OnboardingDraft draft) {
    final committed = draft.committed;
    return AcademicRecord(
      semesters: committed != null ? [committed] : const <Semester>[],
      scheme: draft.scheme,
    );
  }

  Future<void> _loadPersisted() async {
    final repository = _repository;
    final schemeRepository = _schemeRepository;
    if (repository == null || schemeRepository == null) return;

    final persistedSemesters = await repository.loadSemesters();
    final persistedScheme = await schemeRepository.loadActiveScheme();

    if (persistedSemesters.isEmpty && persistedScheme == null) return;
    state = AcademicRecord(
      semesters: persistedSemesters.isNotEmpty ? persistedSemesters : state.semesters,
      scheme: persistedScheme ?? state.scheme,
    );
  }

  void addSemester(Semester semester) {
    state = AcademicRecord(
      semesters: [...state.semesters, semester],
      scheme: state.scheme,
    );
    unawaited(_persist(semester));
  }

  void updateSemester(Semester updated) {
    state = AcademicRecord(
      semesters: [
        for (final s in state.semesters) s.id == updated.id ? updated : s,
      ],
      scheme: state.scheme,
    );
    unawaited(_repository?.updateSemester(updated));
  }

  void removeSemester(String id) {
    state = AcademicRecord(
      semesters: state.semesters.where((s) => s.id != id).toList(),
      scheme: state.scheme,
    );
    unawaited(_repository?.removeSemester(id));
  }

  /// Persists the new semester plus a snapshot of the scheme it was
  /// computed under — committing a result is the moment "this is the
  /// scheme in use" becomes true, so both are saved together.
  Future<void> _persist(Semester semester) async {
    await _repository?.addSemester(semester);
    await _schemeRepository?.saveActiveScheme(state.scheme);
  }
}

final academicRecordProvider =
    StateNotifierProvider<AcademicRecordController, AcademicRecord>(
  (ref) => AcademicRecordController(
    ref,
    ref.watch(academicRecordRepositoryProvider),
    ref.watch(gradingSchemeRepositoryProvider),
  ),
);

/// The single source of computed truth for the signed-in student. Every
/// number shown on Home, Academics and Roadmap must originate here — see
/// "THE RULE THAT MATTERS MOST" in AGENTS.md.
final standingProvider = Provider<AcademicStanding>((ref) {
  final record = ref.watch(academicRecordProvider);
  return CgpaEngine.computeStanding(
    semesters: record.semesters,
    scheme: record.scheme,
  );
});

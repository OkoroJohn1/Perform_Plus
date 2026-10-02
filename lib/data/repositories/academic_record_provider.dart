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

  /// Completes once startup persistence/reload work is done. The reactive
  /// `state` is what production code should use — this exists so tests can
  /// await a cold start (persist-then-reload) before asserting on state,
  /// instead of guessing at a delay.
  late final Future<void> ready;

  AcademicRecordController(
    Ref ref,
    AcademicRecordRepository repository,
    GradingSchemeRepository schemeRepository,
  )   : _repository = repository,
        _schemeRepository = schemeRepository,
        super(_seedFrom(ref.read(onboardingDraftProvider))) {
    ref.listen(onboardingDraftProvider, (previous, next) {
      // Fires for the *first* commit only if this controller already
      // existed when it happened — see `_init` below for the far more
      // common case where Add Results commits before anything has ever
      // watched `academicRecordProvider`. The id comparison (rather than a
      // null check) also catches a second/third semester committed via
      // "Add another semester first", which a null check would miss since
      // `committed` is never reset to null between commits.
      final committed = next.committed;
      if (committed != null && committed.id != previous?.committed?.id) {
        addSemester(committed);
      }
    });
    ready = _init(ref.read(onboardingDraftProvider).committed);
  }

  /// Fixed-state constructor for widget tests — bypasses the onboarding
  /// draft and Drift entirely so a test can hand it an exact [AcademicRecord].
  AcademicRecordController.seeded(super.record)
      : _repository = null,
        _schemeRepository = null {
    ready = Future.value();
  }

  /// `_seedFrom` (in the initializer list above) already folds a
  /// pre-existing committed draft into the initial in-memory state, but it
  /// never reaches the database that way. In practice the onboarding draft
  /// is *always* already committed by the time this controller is first
  /// created — Add Results commits it, then GPA reveal, Sign In and Profile
  /// Setup all run without ever watching `academicRecordProvider`; Backfill
  /// is the first screen that does. Because `ref.listen` above only fires on
  /// a transition *after* it's registered, that first semester would
  /// otherwise sit in memory only and vanish on the next launch. Persisting
  /// it here — before `_loadPersisted` runs — closes that gap.
  Future<void> _init(Semester? alreadyCommittedBeforeInit) async {
    if (alreadyCommittedBeforeInit != null) {
      await _persist(alreadyCommittedBeforeInit);
    }
    await _loadPersisted();
  }

  static AcademicRecord _seedFrom(OnboardingDraft draft) {
    final committed = draft.committed;
    return AcademicRecord(
      semesters: committed != null ? [committed] : const <Semester>[],
      scheme: draft.scheme,
    );
  }

  /// Re-reads Drift and folds in whatever's there. Public so the dashboard's
  /// pull-to-refresh can force a reload from disk — there is no remote
  /// mirror of the academic record to sync from yet (unlike the profile
  /// screen's `ProfileRemoteSync`), so "refresh" means "trust the local
  /// database again," not a network round-trip.
  Future<void> refresh() => _loadPersisted();

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

  /// Used by the settings screen's Institution and Grading scheme rows --
  /// changing either re-resolves the scheme every subsequent CGPA
  /// computation reads (`standingProvider` derives from this state), so a
  /// caller must recompute and show the before/after delta itself (see
  /// `CgpaEngine.recalculate`) rather than assuming this is silent.
  void updateScheme(GradingScheme scheme) {
    state = AcademicRecord(semesters: state.semesters, scheme: scheme);
    unawaited(_schemeRepository?.saveActiveScheme(scheme));
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

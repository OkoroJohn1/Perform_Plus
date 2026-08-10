/// The signed-in student's full academic record.
///
/// TODO(v1): replace with a Drift-backed repository once local storage
/// lands — `data/local` is not yet built. Until then this holds in-memory
/// CRUD state, seeded from the onboarding draft's committed semester so a
/// student who just finished the Add Results screen sees that semester
/// here rather than an empty record they'd have to re-enter.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/engine/cgpa_engine.dart';
import '../../domain/models/course_result.dart';
import '../../domain/models/grading_scheme.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';

class AcademicRecord {
  final List<Semester> semesters;
  final GradingScheme scheme;

  const AcademicRecord({required this.semesters, required this.scheme});
}

class AcademicRecordController extends StateNotifier<AcademicRecord> {
  AcademicRecordController(Ref ref)
      : super(_seedFrom(ref.read(onboardingDraftProvider))) {
    ref.listen(onboardingDraftProvider, (previous, next) {
      // The draft's committed semester only ever appears once, right after
      // the Add Results screen commits it. Re-seeding on every draft change
      // would clobber Results CRUD done afterwards, so only fold it in the
      // first time.
      if (previous?.committed == null && next.committed != null) {
        addSemester(next.committed!);
      }
    });
  }

  /// Fixed-state constructor for widget tests — bypasses the onboarding
  /// draft entirely so a test can hand it an exact [AcademicRecord].
  AcademicRecordController.seeded(super.record);

  static AcademicRecord _seedFrom(OnboardingDraft draft) {
    final committed = draft.committed;
    return AcademicRecord(
      semesters: committed != null ? [committed] : const <Semester>[],
      scheme: draft.scheme,
    );
  }

  void addSemester(Semester semester) {
    state = AcademicRecord(
      semesters: [...state.semesters, semester],
      scheme: state.scheme,
    );
  }

  void updateSemester(Semester updated) {
    state = AcademicRecord(
      semesters: [
        for (final s in state.semesters) s.id == updated.id ? updated : s,
      ],
      scheme: state.scheme,
    );
  }

  void removeSemester(String id) {
    state = AcademicRecord(
      semesters: state.semesters.where((s) => s.id != id).toList(),
      scheme: state.scheme,
    );
  }
}

final academicRecordProvider =
    StateNotifierProvider<AcademicRecordController, AcademicRecord>(
  (ref) => AcademicRecordController(ref),
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

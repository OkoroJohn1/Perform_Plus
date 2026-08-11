/// Onboarding draft state.
///
/// Holds results entered during Act 1, BEFORE any account exists. Persisted
/// locally so a student who closes the app mid-entry does not lose work and
/// so the draft survives to be attached to an account at signup.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/seed/nigerian_institutions.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';

const _uuid = Uuid();

/// A single editable row in the entry / review table.
class DraftResultRow {
  final String courseCode;
  final String? courseTitle;
  final int? creditUnit;
  final String? grade;
  final double? extractionConfidence;

  const DraftResultRow({
    this.courseCode = '',
    this.courseTitle,
    this.creditUnit,
    this.grade,
    this.extractionConfidence,
  });

  bool get isComplete =>
      courseCode.trim().isNotEmpty && creditUnit != null && grade != null;

  bool get needsReview =>
      extractionConfidence != null &&
      extractionConfidence! < AppConstants.ocrReviewThreshold;

  DraftResultRow copyWith({
    String? courseCode,
    String? courseTitle,
    int? creditUnit,
    String? grade,
    double? extractionConfidence,
  }) =>
      DraftResultRow(
        courseCode: courseCode ?? this.courseCode,
        courseTitle: courseTitle ?? this.courseTitle,
        creditUnit: creditUnit ?? this.creditUnit,
        grade: grade ?? this.grade,
        extractionConfidence:
            extractionConfidence ?? this.extractionConfidence,
      );
}

class OnboardingDraft {
  final String institutionId;
  final GradingScheme scheme;
  final String session;
  final int level;
  final SemesterTerm term;
  final List<DraftResultRow> rows;
  final Semester? committed;

  const OnboardingDraft({
    required this.institutionId,
    required this.scheme,
    required this.session,
    required this.level,
    required this.term,
    required this.rows,
    this.committed,
  });

  bool get hasFlaggedRows => rows.any((r) => r.needsReview);
  int get flaggedCount => rows.where((r) => r.needsReview).length;

  /// Duplicate course codes are the most common manual-entry error and they
  /// silently inflate the denominator.
  List<String> get duplicateCodes {
    final seen = <String>{};
    final dupes = <String>{};
    for (final r in rows.where((r) => r.courseCode.trim().isNotEmpty)) {
      final code = r.courseCode.trim().toUpperCase();
      if (!seen.add(code)) dupes.add(code);
    }
    return dupes.toList();
  }

  OnboardingDraft copyWith({
    String? institutionId,
    GradingScheme? scheme,
    String? session,
    int? level,
    SemesterTerm? term,
    List<DraftResultRow>? rows,
    Semester? committed,
  }) =>
      OnboardingDraft(
        institutionId: institutionId ?? this.institutionId,
        scheme: scheme ?? this.scheme,
        session: session ?? this.session,
        level: level ?? this.level,
        term: term ?? this.term,
        rows: rows ?? this.rows,
        committed: committed ?? this.committed,
      );
}

class OnboardingDraftNotifier extends StateNotifier<OnboardingDraft> {
  OnboardingDraftNotifier()
      : super(OnboardingDraft(
          // FUTO-only for now — no institution picker. See AGENTS.md's
          // "Open questions" for the one-institution-at-launch rationale.
          institutionId: 'futo',
          scheme: defaultSchemes['futo']!,
          session: _currentSession(),
          level: 100,
          term: SemesterTerm.first,
          rows: const [DraftResultRow()],
        ));

  static String _currentSession() {
    final y = DateTime.now().year;
    // Nigerian sessions typically run Sept-Aug.
    return DateTime.now().month >= 9 ? '$y/${y + 1}' : '${y - 1}/$y';
  }

  void setInstitution(String institutionId) {
    state = state.copyWith(
      institutionId: institutionId,
      scheme: defaultSchemes[institutionId] ?? fallbackScheme,
    );
  }

  void setScheme(GradingScheme scheme) => state = state.copyWith(scheme: scheme);

  void setSemesterContext({String? session, int? level, SemesterTerm? term}) {
    state = state.copyWith(session: session, level: level, term: term);
  }

  void addBlankRow() =>
      state = state.copyWith(rows: [...state.rows, const DraftResultRow()]);

  void updateRow(int index, DraftResultRow row) {
    final rows = [...state.rows]..[index] = row;
    state = state.copyWith(rows: rows);
  }

  void removeRow(int index) {
    final rows = [...state.rows]..removeAt(index);
    state = state.copyWith(rows: rows.isEmpty ? [const DraftResultRow()] : rows);
  }

  void replaceRows(List<DraftResultRow> rows) =>
      state = state.copyWith(rows: rows);

  /// Turn complete draft rows into a real Semester.
  void commitDraft() {
    final now = DateTime.now();
    final semesterId = _uuid.v4();

    final results = state.rows.where((r) => r.isComplete).map((r) {
      return CourseResult(
        id: _uuid.v4(),
        semesterId: semesterId,
        courseCode: r.courseCode.trim().toUpperCase(),
        courseTitle: r.courseTitle,
        creditUnit: r.creditUnit!,
        grade: r.grade!,
        source: r.extractionConfidence != null
            ? ResultSource.ocrImport
            : ResultSource.manual,
        extractionConfidence: r.extractionConfidence,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    state = state.copyWith(
      committed: Semester(
        id: semesterId,
        profileId: AppConstants.localProfileId,
        session: state.session,
        term: state.term,
        level: state.level,
        results: results,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

final onboardingDraftProvider =
    StateNotifierProvider<OnboardingDraftNotifier, OnboardingDraft>(
  (ref) => OnboardingDraftNotifier(),
);

/// The computed GPA for the draft semester. Pure engine call, no network,
/// no auth. This is the Act 1 payoff.
final draftComputationProvider = Provider<SemesterComputation?>((ref) {
  final draft = ref.watch(onboardingDraftProvider);
  final semester = draft.committed;
  if (semester == null) return null;
  return CgpaEngine.computeSemester(
    semester: semester,
    scheme: draft.scheme,
  );
});

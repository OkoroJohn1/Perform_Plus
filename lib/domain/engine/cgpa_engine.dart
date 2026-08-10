/// The CGPA engine.
///
/// ARCHITECTURAL CONTRACT — do not violate:
///   * This file is pure. No I/O, no async, no Flutter imports, no network.
///   * The AI layer NEVER performs arithmetic. It consumes the outputs of
///     this engine via function calling and only phrases them in prose.
///     If a model is asked to compute a CGPA it will hallucinate one.
///   * Every number the user sees must originate here.
library;

import '../models/course_result.dart';
import '../models/grading_scheme.dart';

/// The computed outcome for a single semester.
class SemesterComputation {
  final String semesterId;
  final int level;
  final SemesterTerm term;
  final String session;

  /// Quality points earned this semester (grade point x credit unit, summed).
  final double qualityPoints;

  /// Credit units counted in the denominator for this semester.
  final int creditUnits;

  /// Credit units actually passed (excludes failures).
  final int creditsPassed;

  final double gpa;

  /// Results excluded from the calculation and why.
  final List<ExcludedResult> excluded;

  const SemesterComputation({
    required this.semesterId,
    required this.level,
    required this.term,
    required this.session,
    required this.qualityPoints,
    required this.creditUnits,
    required this.creditsPassed,
    required this.gpa,
    this.excluded = const [],
  });

  String get shortLabel => '${level}L ${term.shortLabel}';
}

/// A result that was not counted, with a human-readable reason.
/// Surfaced in the UI so a student can always answer "why isn't this
/// course in my CGPA?" without contacting support.
class ExcludedResult {
  final String resultId;
  final String courseCode;
  final String reason;

  const ExcludedResult({
    required this.resultId,
    required this.courseCode,
    required this.reason,
  });
}

/// A problem found during calculation. Never thrown — collected and returned
/// so a single bad row cannot blank the entire dashboard.
class CalculationIssue {
  final String? resultId;
  final String courseCode;
  final String message;
  final IssueSeverity severity;

  const CalculationIssue({
    this.resultId,
    required this.courseCode,
    required this.message,
    this.severity = IssueSeverity.warning,
  });
}

enum IssueSeverity { warning, error }

/// The complete academic standing of a student at a point in time.
class AcademicStanding {
  final double cgpa;
  final double totalQualityPoints;
  final int totalCreditUnits;
  final int totalCreditsPassed;
  final ClassificationBand? classification;
  final List<SemesterComputation> semesters;
  final List<CalculationIssue> issues;

  const AcademicStanding({
    required this.cgpa,
    required this.totalQualityPoints,
    required this.totalCreditUnits,
    required this.totalCreditsPassed,
    this.classification,
    this.semesters = const [],
    this.issues = const [],
  });

  bool get hasData => totalCreditUnits > 0;
  bool get hasErrors =>
      issues.any((i) => i.severity == IssueSeverity.error);

  /// Best semester GPA on record. The projection solver uses this as the
  /// honest benchmark for feasibility rather than inventing a probability.
  double? get bestSemesterGpa {
    final withData = semesters.where((s) => s.creditUnits > 0);
    if (withData.isEmpty) return null;
    return withData.map((s) => s.gpa).reduce((a, b) => a > b ? a : b);
  }

  double? get worstSemesterGpa {
    final withData = semesters.where((s) => s.creditUnits > 0);
    if (withData.isEmpty) return null;
    return withData.map((s) => s.gpa).reduce((a, b) => a < b ? a : b);
  }

  /// Cumulative CGPA after each semester, in chronological order — the
  /// series a trend chart plots. A single point cannot show a trend, so
  /// callers with fewer than two semesters should not render it as a line.
  List<double> get cumulativeCgpaTrend {
    double qp = 0;
    int units = 0;
    return semesters.map((s) {
      qp += s.qualityPoints;
      units += s.creditUnits;
      return units == 0 ? 0.0 : CgpaEngine.round2(qp / units);
    }).toList();
  }

  /// Trend across the last [window] semesters. Positive means improving.
  double? recentTrend({int window = 3}) {
    final withData =
        semesters.where((s) => s.creditUnits > 0).toList();
    if (withData.length < 2) return null;
    final slice = withData.length <= window
        ? withData
        : withData.sublist(withData.length - window);
    return slice.last.gpa - slice.first.gpa;
  }

  static const empty = AcademicStanding(
    cgpa: 0,
    totalQualityPoints: 0,
    totalCreditUnits: 0,
    totalCreditsPassed: 0,
  );
}

/// Pure calculation engine. All methods are static and side-effect free.
class CgpaEngine {
  const CgpaEngine._();

  /// Rounding used for all displayed values. Two decimal places matches
  /// what Nigerian universities print on transcripts.
  static double round2(double value) => (value * 100).roundToDouble() / 100;

  /// Compute one semester's GPA.
  ///
  /// [allResults] is every result across the whole academic record (every
  /// semester, not just earlier ones), needed to detect which failing rows
  /// in this semester are later superseded by a repeat — the repeat is
  /// almost always in a *later* semester, so "earlier only" would never
  /// find it.
  static SemesterComputation computeSemester({
    required Semester semester,
    required GradingScheme scheme,
    List<CourseResult> allResults = const [],
    List<CalculationIssue>? issueSink,
  }) {
    double qualityPoints = 0;
    int creditUnits = 0;
    int creditsPassed = 0;
    final excluded = <ExcludedResult>[];

    for (final result in semester.results) {
      final definition = scheme.definitionForLetter(result.grade);

      // Unknown letter grade. Excluded rather than silently zeroed —
      // a silent zero corrupts the CGPA with no visible cause.
      if (definition == null) {
        issueSink?.add(CalculationIssue(
          resultId: result.id,
          courseCode: result.courseCode,
          message:
              'Grade "${result.grade}" is not defined in ${scheme.name}.',
          severity: IssueSeverity.error,
        ));
        excluded.add(ExcludedResult(
          resultId: result.id,
          courseCode: result.courseCode,
          reason: 'Unrecognised grade',
        ));
        continue;
      }

      if (result.creditUnit <= 0) {
        issueSink?.add(CalculationIssue(
          resultId: result.id,
          courseCode: result.courseCode,
          message: 'Credit unit must be greater than zero.',
          severity: IssueSeverity.error,
        ));
        excluded.add(ExcludedResult(
          resultId: result.id,
          courseCode: result.courseCode,
          reason: 'Invalid credit unit',
        ));
        continue;
      }

      var effectivePoint = definition.point;

      // Carryover handling. This is where institutions diverge and where
      // a wrong assumption produces a plausible-looking wrong number.
      if (result.isRepeat) {
        switch (scheme.repeatPolicy) {
          case RepeatPolicy.countBothAttempts:
            // Nothing to adjust here — the original failure stays in its
            // own semester and this attempt counts normally.
            break;

          case RepeatPolicy.replaceOriginal:
            // The original is excluded when its own semester is computed;
            // see [_isSupersededBy]. This attempt counts at face value.
            break;

          case RepeatPolicy.replaceWithCap:
            final cap = scheme.repeatCapPoint;
            if (cap != null && effectivePoint > cap) {
              effectivePoint = cap;
              issueSink?.add(CalculationIssue(
                resultId: result.id,
                courseCode: result.courseCode,
                message:
                    'Repeat grade capped at $cap under ${scheme.name} policy.',
                severity: IssueSeverity.warning,
              ));
            }
            break;
        }
      }

      // Under replaceOriginal, a failure that was later repeated is dropped
      // from its original semester.
      if (scheme.repeatPolicy == RepeatPolicy.replaceOriginal &&
          definition.isFailing &&
          _isSupersededLater(result, allResults)) {
        excluded.add(ExcludedResult(
          resultId: result.id,
          courseCode: result.courseCode,
          reason: 'Superseded by a later repeat',
        ));
        continue;
      }

      qualityPoints += effectivePoint * result.creditUnit;
      creditUnits += result.creditUnit;
      if (!definition.isFailing) creditsPassed += result.creditUnit;
    }

    final gpa = creditUnits == 0 ? 0.0 : round2(qualityPoints / creditUnits);

    return SemesterComputation(
      semesterId: semester.id,
      level: semester.level,
      term: semester.term,
      session: semester.session,
      qualityPoints: qualityPoints,
      creditUnits: creditUnits,
      creditsPassed: creditsPassed,
      gpa: gpa,
      excluded: excluded,
    );
  }

  /// Compute full academic standing across all semesters.
  ///
  /// Semesters are sorted chronologically before computation because
  /// carryover detection depends on knowing what came before.
  static AcademicStanding computeStanding({
    required List<Semester> semesters,
    required GradingScheme scheme,
  }) {
    if (semesters.isEmpty) return AcademicStanding.empty;

    final ordered = [...semesters]
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

    final allResults = List<CourseResult>.unmodifiable(
      ordered.expand((s) => s.results),
    );

    final issues = <CalculationIssue>[];
    final computations = <SemesterComputation>[];

    double totalQp = 0;
    int totalUnits = 0;
    int totalPassed = 0;

    for (final semester in ordered) {
      final computation = computeSemester(
        semester: semester,
        scheme: scheme,
        allResults: allResults,
        issueSink: issues,
      );

      computations.add(computation);
      totalQp += computation.qualityPoints;
      totalUnits += computation.creditUnits;
      totalPassed += computation.creditsPassed;
    }

    final cgpa = totalUnits == 0 ? 0.0 : round2(totalQp / totalUnits);

    return AcademicStanding(
      cgpa: cgpa,
      totalQualityPoints: totalQp,
      totalCreditUnits: totalUnits,
      totalCreditsPassed: totalPassed,
      classification: scheme.classify(cgpa),
      semesters: computations,
      issues: issues,
    );
  }

  /// Recalculate from a mutated semester list.
  ///
  /// Editing a 200-level grade must cascade through every downstream
  /// semester. Rather than patching incrementally — which drifts — the
  /// engine is cheap enough to simply recompute the whole record.
  /// Returns both the new standing and the delta for the UI to show.
  static RecalculationResult recalculate({
    required List<Semester> semesters,
    required GradingScheme scheme,
    required AcademicStanding previous,
  }) {
    final updated = computeStanding(semesters: semesters, scheme: scheme);
    return RecalculationResult(
      previous: previous,
      updated: updated,
      cgpaDelta: round2(updated.cgpa - previous.cgpa),
    );
  }

  /// Detect whether a failed result is repeated in a later attempt,
  /// regardless of whether that attempt falls in an earlier or later
  /// semester in the sorted order.
  static bool _isSupersededLater(
    CourseResult result,
    List<CourseResult> allResults,
  ) {
    final code = result.courseCode.trim().toUpperCase();
    return allResults.any((r) =>
        r.id != result.id &&
        r.courseCode.trim().toUpperCase() == code &&
        r.attempt > result.attempt);
  }
}

/// The before/after pair shown to a student when their record changes.
/// Making the change visible is what turns result entry into a reward
/// rather than a chore.
class RecalculationResult {
  final AcademicStanding previous;
  final AcademicStanding updated;
  final double cgpaDelta;

  const RecalculationResult({
    required this.previous,
    required this.updated,
    required this.cgpaDelta,
  });

  bool get improved => cgpaDelta > 0;
  bool get unchanged => cgpaDelta == 0;

  bool get classificationChanged =>
      previous.classification?.label != updated.classification?.label;
}

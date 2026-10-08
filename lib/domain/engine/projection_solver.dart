/// Projection solver.
///
/// Answers two questions:
///   forward  — "if I score X from here, where do I land?"
///   backward — "what do I need to score to reach Y?"
///
/// Deliberately contains NO probability model. A percentage like
/// "68% likely to make First Class" would be fabricated — there is no
/// training data, no cohort baseline, and no honest way to produce it from
/// one student's transcript. Instead, feasibility is expressed against the
/// student's own demonstrated performance, which is both defensible and
/// more motivating: "this would require beating your best-ever semester in
/// all four remaining semesters" lands harder than a made-up number.
library;

import 'dart:math' as math;

import 'cgpa_engine.dart';
import '../models/grading_scheme.dart';

/// How hard a target is, derived strictly from the student's own record.
enum Feasibility {
  /// Already achieved at current standing.
  secured,

  /// Requires less than the student's current CGPA. Coasting suffices.
  comfortable,

  /// Requires above current CGPA but at or below their demonstrated best.
  withinReach,

  /// Requires exceeding their best-ever semester GPA.
  demanding,

  /// Requires a GPA at or near the scheme maximum in every remaining term.
  extremelyDemanding,

  /// Arithmetically impossible — required GPA exceeds the scheme maximum.
  unreachable,
}

extension FeasibilityLabel on Feasibility {
  String get label => switch (this) {
        Feasibility.secured => 'Already secured',
        Feasibility.comfortable => 'Comfortable',
        Feasibility.withinReach => 'Within reach',
        Feasibility.demanding => 'Demanding',
        Feasibility.extremelyDemanding => 'Extremely demanding',
        Feasibility.unreachable => 'Not reachable',
      };
}

/// The result of a backward projection.
class TargetProjection {
  final double targetCgpa;
  final String? targetLabel;

  final double currentCgpa;
  final int creditsEarned;
  final int creditsRemaining;
  final int semestersRemaining;

  /// The average grade point needed across all remaining credits.
  /// Null when [creditsRemaining] is zero.
  final double? requiredAverage;

  final Feasibility feasibility;

  /// Student's best semester GPA to date, for honest comparison.
  final double? personalBest;

  /// The highest band still achievable. Populated when the requested
  /// target is [Feasibility.unreachable] so the UI always has somewhere
  /// constructive to point.
  final ClassificationBand? nearestAchievable;

  /// The best CGPA attainable if every remaining credit scored maximum.
  final double ceilingCgpa;

  /// The CGPA if the student maintains exactly their current average.
  final double coastingCgpa;

  const TargetProjection({
    required this.targetCgpa,
    this.targetLabel,
    required this.currentCgpa,
    required this.creditsEarned,
    required this.creditsRemaining,
    required this.semestersRemaining,
    required this.requiredAverage,
    required this.feasibility,
    this.personalBest,
    this.nearestAchievable,
    required this.ceilingCgpa,
    required this.coastingCgpa,
  });

  bool get isReachable => feasibility != Feasibility.unreachable;

  /// Structured payload handed to the AI advisor via function calling.
  /// The model receives these computed facts and phrases them. It is never
  /// given raw grades and asked to do arithmetic.
  Map<String, dynamic> toAdvisorPayload() => {
        'target_cgpa': targetCgpa,
        'target_label': targetLabel,
        'current_cgpa': currentCgpa,
        'credits_earned': creditsEarned,
        'credits_remaining': creditsRemaining,
        'semesters_remaining': semestersRemaining,
        'required_average_gpa': requiredAverage,
        'feasibility': feasibility.name,
        'personal_best_semester_gpa': personalBest,
        'ceiling_cgpa': ceilingCgpa,
        'coasting_cgpa': coastingCgpa,
        'nearest_achievable_label': nearestAchievable?.label,
        'is_reachable': isReachable,
      };
}

/// The result of a forward simulation ("what if I score X?").
class ForwardProjection {
  final double assumedGpa;
  final double projectedCgpa;
  final ClassificationBand? projectedClassification;
  final double deltaFromCurrent;

  const ForwardProjection({
    required this.assumedGpa,
    required this.projectedCgpa,
    this.projectedClassification,
    required this.deltaFromCurrent,
  });
}

class ProjectionSolver {
  const ProjectionSolver._();

  /// Typical Nigerian degree structure. Overridable per profile because
  /// Engineering, Medicine, and Law run different lengths.
  static const int defaultCreditsPerSemester = 20;

  /// Backward projection: what average is needed to hit [targetCgpa]?
  ///
  /// Under [CgpaAggregationMode.creditWeighted]:
  ///
  ///   target = (earnedQP + x * remainingCredits)
  ///            / (earnedCredits + remainingCredits)
  ///
  /// Solving for x:
  ///
  ///   x = (target * (earnedCredits + remainingCredits) - earnedQP)
  ///       / remainingCredits
  ///
  /// Under [CgpaAggregationMode.recursiveSemesterAverage] the relationship
  /// is entirely different -- there is no credit-unit term at all, and
  /// sustaining the same GPA `x` for `k` more semesters compounds
  /// geometrically rather than linearly. Projecting forward `k` semesters
  /// from current CGPA `C` at a sustained GPA `x` gives
  /// `x + (C - x) / 2^k` (provable by induction from the recurrence
  /// `CGPAₙ = (CGPAₙ₋₁ + x) / 2`); solving that for `x` against a target
  /// `T` gives `x = (2^k·T - C) / (2^k - 1)`. See `_solveLinear`/
  /// `_solveRecursive` below for each branch in full.
  static TargetProjection solveForTarget({
    required AcademicStanding standing,
    required GradingScheme scheme,
    required double targetCgpa,
    String? targetLabel,
    required int semestersRemaining,
    int creditsPerSemester = defaultCreditsPerSemester,
  }) {
    final earnedCredits = standing.totalCreditUnits;
    final remainingCredits = semestersRemaining * creditsPerSemester;

    // No credits/semesters left — the record is final, regardless of mode.
    if (remainingCredits == 0) {
      return TargetProjection(
        targetCgpa: targetCgpa,
        targetLabel: targetLabel,
        currentCgpa: standing.cgpa,
        creditsEarned: earnedCredits,
        creditsRemaining: 0,
        semestersRemaining: 0,
        requiredAverage: null,
        feasibility: standing.cgpa >= targetCgpa
            ? Feasibility.secured
            : Feasibility.unreachable,
        personalBest: standing.bestSemesterGpa,
        nearestAchievable: scheme.classify(standing.cgpa),
        ceilingCgpa: standing.cgpa,
        coastingCgpa: standing.cgpa,
      );
    }

    final (required, ceiling, coasting) = switch (scheme.cgpaAggregation) {
      CgpaAggregationMode.creditWeighted => _solveLinear(
          standing: standing,
          scheme: scheme,
          targetCgpa: targetCgpa,
          earnedCredits: earnedCredits,
          remainingCredits: remainingCredits,
        ),
      CgpaAggregationMode.recursiveSemesterAverage => _solveRecursive(
          standing: standing,
          scheme: scheme,
          targetCgpa: targetCgpa,
          semestersRemaining: semestersRemaining,
        ),
    };

    final feasibility = _assess(
      required: required,
      currentCgpa: standing.cgpa,
      targetCgpa: targetCgpa,
      personalBest: standing.bestSemesterGpa,
      maxPoint: scheme.maxPoint,
    );

    ClassificationBand? nearest;
    if (feasibility == Feasibility.unreachable) {
      nearest =
          scheme.bandsDescending.where((b) => b.minCgpa <= ceiling).firstOrNull;
    }

    return TargetProjection(
      targetCgpa: targetCgpa,
      targetLabel: targetLabel,
      currentCgpa: standing.cgpa,
      creditsEarned: earnedCredits,
      creditsRemaining: remainingCredits,
      semestersRemaining: semestersRemaining,
      requiredAverage: required,
      feasibility: feasibility,
      personalBest: standing.bestSemesterGpa,
      nearestAchievable: nearest,
      ceilingCgpa: ceiling,
      coastingCgpa: coasting,
    );
  }

  /// Forward projection: where does a sustained [assumedGpa] land you?
  static ForwardProjection simulate({
    required AcademicStanding standing,
    required GradingScheme scheme,
    required double assumedGpa,
    required int semestersRemaining,
    int creditsPerSemester = defaultCreditsPerSemester,
  }) {
    final projected = switch (scheme.cgpaAggregation) {
      CgpaAggregationMode.creditWeighted => _projectLinear(
          standing: standing,
          assumedGpa: assumedGpa,
          remainingCredits: semestersRemaining * creditsPerSemester,
        ),
      CgpaAggregationMode.recursiveSemesterAverage => _projectRecursive(
          currentCgpa: standing.cgpa,
          assumedGpa: assumedGpa,
          semestersRemaining: semestersRemaining,
        ),
    };

    return ForwardProjection(
      assumedGpa: assumedGpa,
      projectedCgpa: projected,
      projectedClassification: scheme.classify(projected),
      deltaFromCurrent: CgpaEngine.round2(projected - standing.cgpa),
    );
  }

  static double _projectLinear({
    required AcademicStanding standing,
    required double assumedGpa,
    required int remainingCredits,
  }) {
    final totalCredits = standing.totalCreditUnits + remainingCredits;
    if (totalCredits == 0) return 0.0;
    return CgpaEngine.round2(
      (standing.totalQualityPoints + assumedGpa * remainingCredits) /
          totalCredits,
    );
  }

  /// `x + (C - x) / 2^k` -- see [solveForTarget]'s doc comment for the
  /// derivation. `k == 0` (nothing left to project) is already filtered
  /// out by every caller before this is reached.
  static double _projectRecursive({
    required double currentCgpa,
    required double assumedGpa,
    required int semestersRemaining,
  }) {
    final decay = math.pow(2, semestersRemaining).toDouble();
    return CgpaEngine.round2(assumedGpa + (currentCgpa - assumedGpa) / decay);
  }

  static (double required, double ceiling, double coasting) _solveLinear({
    required AcademicStanding standing,
    required GradingScheme scheme,
    required double targetCgpa,
    required int earnedCredits,
    required int remainingCredits,
  }) {
    final earnedQp = standing.totalQualityPoints;
    final totalCredits = earnedCredits + remainingCredits;

    final ceiling = CgpaEngine.round2(
      (earnedQp + scheme.maxPoint * remainingCredits) / totalCredits,
    );
    final coasting = CgpaEngine.round2(
      (earnedQp + standing.cgpa * remainingCredits) / totalCredits,
    );
    final required = CgpaEngine.round2(
      (targetCgpa * totalCredits - earnedQp) / remainingCredits,
    );
    return (required, ceiling, coasting);
  }

  /// `x = (2^k·T - C) / (2^k - 1)`, the inverse of [_projectRecursive]'s
  /// forward formula -- see [solveForTarget]'s doc comment.
  static (double required, double ceiling, double coasting) _solveRecursive({
    required AcademicStanding standing,
    required GradingScheme scheme,
    required double targetCgpa,
    required int semestersRemaining,
  }) {
    final currentCgpa = standing.cgpa;
    final decay = math.pow(2, semestersRemaining).toDouble();

    final ceiling = _projectRecursive(
      currentCgpa: currentCgpa,
      assumedGpa: scheme.maxPoint,
      semestersRemaining: semestersRemaining,
    );
    // Sustaining exactly the current CGPA as every future semester's GPA
    // is a fixed point of the recurrence -- the average of C and C is C --
    // so coasting always equals today's CGPA under this mode.
    final coasting = currentCgpa;
    final required = CgpaEngine.round2(
      (decay * targetCgpa - currentCgpa) / (decay - 1),
    );
    return (required, ceiling, coasting);
  }

  /// Every classification band with its required average, for the goal
  /// picker. Lets a student see the full menu with real costs attached
  /// before committing to a target.
  static List<TargetProjection> allBandProjections({
    required AcademicStanding standing,
    required GradingScheme scheme,
    required int semestersRemaining,
    int creditsPerSemester = defaultCreditsPerSemester,
  }) =>
      scheme.bandsDescending
          .map((band) => solveForTarget(
                standing: standing,
                scheme: scheme,
                targetCgpa: band.minCgpa,
                targetLabel: band.label,
                semestersRemaining: semestersRemaining,
                creditsPerSemester: creditsPerSemester,
              ))
          .toList();

  static Feasibility _assess({
    required double required,
    required double currentCgpa,
    required double targetCgpa,
    required double? personalBest,
    required double maxPoint,
  }) {
    if (currentCgpa >= targetCgpa && required <= currentCgpa) {
      return Feasibility.secured;
    }
    if (required > maxPoint) return Feasibility.unreachable;
    // 0.98 of max (4.90 on a 5.0 scale) means near-perfect grades in every
    // remaining course. Below that, "demanding" is the honest word — 4.80
    // is very hard but students do achieve it.
    if (required >= maxPoint * 0.98) return Feasibility.extremelyDemanding;
    if (required <= currentCgpa) return Feasibility.comfortable;
    if (personalBest != null && required > personalBest) {
      return Feasibility.demanding;
    }
    return Feasibility.withinReach;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

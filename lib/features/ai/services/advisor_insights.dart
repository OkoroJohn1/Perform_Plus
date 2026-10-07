/// Advisor insight generation — pure Dart, no Flutter imports.
///
/// Every card here is TEMPLATE-GENERATED from [CgpaEngine]/[ProjectionSolver]
/// output, never model-generated. See AGENTS.md's "THE RULE THAT MATTERS
/// MOST": the LLM never performs arithmetic. When chat is wired later, the
/// model receives [TargetProjection.toAdvisorPayload] — computed facts —
/// and phrases them; it never sees raw grades. These cards work today with
/// no API key and are deterministic and verifiable, which is exactly why
/// they must not be routed through an LLM.
library;

import 'package:collection/collection.dart';

import '../../../data/seed/nigerian_institutions.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/engine/projection_solver.dart';
import '../../../domain/models/backfill_plan.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';
import '../../../domain/models/student_profile.dart';

String _fmt(double v) => v.toStringAsFixed(2);

enum InsightKind { goalPace, trend, weakestCreditLoad, carryovers, nextEntry, insufficientData }

enum TrendDirection { rising, falling, steady }

/// One insight card's content. Colour/icon are a presentation concern and
/// live in the UI layer (`ai_shell.dart`) keyed off [kind] — this class
/// only carries computed text, plus the two fields whose colour/icon
/// genuinely varies within a single kind ([feasibility] for goalPace,
/// [trendDirection] for trend) so the UI never has to re-derive them by
/// pattern-matching the title string.
class Insight {
  final InsightKind kind;
  final String title;
  final String body;

  final Feasibility? feasibility;
  final TrendDirection? trendDirection;

  /// Only set on the carryovers card, when the active scheme is
  /// unverified — appended in its own (amber) style rather than folded
  /// into [body].
  final String? warning;

  const Insight({
    required this.kind,
    required this.title,
    required this.body,
    this.feasibility,
    this.trendDirection,
    this.warning,
  });
}

class CriticalStanding {
  final double cgpa;
  final String institutionName;
  final ClassificationBand lowestBand;
  final TargetProjection projectionToLowestBand;

  const CriticalStanding({
    required this.cgpa,
    required this.institutionName,
    required this.lowestBand,
    required this.projectionToLowestBand,
  });
}

class AdvisorState {
  final bool hasData;
  final CriticalStanding? critical;
  final List<Insight> insights;

  const AdvisorState({required this.hasData, required this.critical, required this.insights});

  bool get isCritical => critical != null;
}

/// The single entry point. [semestersRemaining] backs the critical card's
/// "what it would take" projection (against the scheme's lowest band, not
/// the student's chosen goal) and should come from the student's profile —
/// see `semestersRemainingFor`. A null [profile] can't say how many
/// semesters are left, so that projection conservatively assumes none
/// remain rather than inventing a number; it still resolves to a real,
/// defined answer via `ProjectionSolver`'s final-year branch.
AdvisorState buildAdvisorState({
  required AcademicStanding standing,
  required GradingScheme scheme,
  required List<Semester> rawSemesters,
  required ClassificationBand? goalBand,
  required TargetProjection? goalProjection,
  required StudentProfile? profile,
  required int semestersRemaining,
}) {
  if (!standing.hasData || scheme.classifications.isEmpty) {
    return const AdvisorState(hasData: false, critical: null, insights: []);
  }

  final lowestBand = scheme.classifications.reduce((a, b) => a.minCgpa < b.minCgpa ? a : b);
  final isCritical = standing.cgpa < lowestBand.minCgpa;
  final carryover = _carryoverInsight(rawSemesters, scheme);

  if (isCritical) {
    final institution = nigerianInstitutions.firstWhereOrNull((i) => i.id == scheme.institutionId);
    final projection = ProjectionSolver.solveForTarget(
      standing: standing,
      scheme: scheme,
      targetCgpa: lowestBand.minCgpa,
      targetLabel: lowestBand.label,
      semestersRemaining: semestersRemaining,
    );
    return AdvisorState(
      hasData: true,
      critical: CriticalStanding(
        cgpa: standing.cgpa,
        institutionName: institution?.name ?? scheme.name,
        lowestBand: lowestBand,
        projectionToLowestBand: projection,
      ),
      // The critical card is the only surface a student in this position
      // needs; carryovers are the one exception because they're directly
      // actionable regardless of overall standing.
      insights: carryover == null ? const [] : [carryover],
    );
  }

  final insights = <Insight>[];

  if (goalBand != null && goalProjection != null) {
    insights.add(_goalPaceInsight(goalProjection, goalBand, scheme.maxPoint));
  }

  if (standing.semesters.length < 2) {
    insights.add(_insufficientDataInsight());
  } else {
    insights.add(_trendInsight(standing));
    final weakest = _weakestCreditLoadInsight(rawSemesters, standing, scheme);
    if (weakest != null) insights.add(weakest);
  }

  if (carryover != null) insights.add(carryover);

  final nextEntry = _nextEntryInsight(rawSemesters, scheme, profile);
  if (nextEntry != null) insights.add(nextEntry);

  return AdvisorState(hasData: true, critical: null, insights: insights.take(4).toList());
}

/// THE MOCKUP IS WRONG HERE, per the task brief: the classification
/// threshold (e.g. 4.50 for First Class) is not the required average. This
/// always uses [TargetProjection.requiredAverage] — the solved value.
Insight _goalPaceInsight(TargetProjection p, ClassificationBand band, double maxPoint) {
  final title = switch (p.feasibility) {
    Feasibility.secured || Feasibility.comfortable => "You're ahead of your goal",
    Feasibility.withinReach => 'Your goal is in reach',
    Feasibility.demanding => 'Your goal needs a lift',
    Feasibility.extremelyDemanding => 'Your goal is very steep',
    Feasibility.unreachable => 'Time to reset the target',
  };

  final body = switch (p.feasibility) {
    Feasibility.unreachable =>
      'Even a perfect ${_fmt(maxPoint)} every semester lands you at ${_fmt(p.ceilingCgpa)}. '
          '${p.nearestAchievable?.label ?? 'A lower classification'} is still open.',
    _ when p.requiredAverage != null =>
      'Average ${_fmt(p.requiredAverage!)} per semester across your remaining '
          '${p.semestersRemaining} to reach ${band.label}.',
    _ => 'Your record is final at ${_fmt(p.currentCgpa)} against ${band.label}.',
  };

  return Insight(kind: InsightKind.goalPace, title: title, body: body, feasibility: p.feasibility);
}

/// Only praises the trend when the arithmetic supports it — the mockup's
/// unconditional "keep up the great work" is replaced with a real sign
/// check against a 0.05 deadband.
Insight _trendInsight(AcademicStanding standing) {
  final delta = standing.recentTrend(window: 3) ?? 0.0;
  final n = standing.semesters.where((s) => s.creditUnits > 0).length.clamp(0, 3);

  if (delta >= 0.05) {
    return Insight(
      kind: InsightKind.trend,
      title: 'Your CGPA is climbing',
      body: 'Up ${_fmt(delta)} over your last $n semesters.',
      trendDirection: TrendDirection.rising,
    );
  }
  if (delta <= -0.05) {
    return Insight(
      kind: InsightKind.trend,
      title: 'Your CGPA has slipped',
      body: 'Down ${_fmt(delta.abs())} over your last $n semesters.',
      trendDirection: TrendDirection.falling,
    );
  }
  return Insight(
    kind: InsightKind.trend,
    title: 'Your CGPA is steady',
    body: 'Within ${_fmt(delta.abs())} across your last $n semesters.',
    trendDirection: TrendDirection.steady,
  );
}

/// Replaces the mockup's "focus more on core courses" — there is no
/// course-importance taxonomy in this app, but credit units sitting below
/// a C standard are real and computable.
Insight? _weakestCreditLoadInsight(
  List<Semester> rawSemesters,
  AcademicStanding standing,
  GradingScheme scheme,
) {
  final threshold = scheme.pointForLetter('C') ?? 3.0;
  final excludedIds = <String>{};
  for (final comp in standing.semesters) {
    excludedIds.addAll(comp.excluded.map((e) => e.resultId));
  }

  var units = 0;
  for (final s in rawSemesters) {
    for (final r in s.results) {
      if (excludedIds.contains(r.id)) continue;
      final point = scheme.pointForLetter(r.grade);
      if (point != null && point < threshold) units += r.creditUnit;
    }
  }

  if (units == 0) return null;
  return Insight(
    kind: InsightKind.weakestCreditLoad,
    title: "Where you're losing points",
    body: '$units credit units sit at C or below. Lifting those moves your CGPA most.',
  );
}

/// A carryover course is any code with more than one attempt on record, or
/// a single attempt that's still failing — mirrors the Academics tab's
/// carryover section so the two screens never disagree on the count.
Insight? _carryoverInsight(List<Semester> rawSemesters, GradingScheme scheme) {
  final byCode = <String, List<CourseResult>>{};
  for (final s in rawSemesters) {
    for (final r in s.results) {
      byCode.putIfAbsent(r.courseCode, () => []).add(r);
    }
  }
  final count = byCode.values
      .where((results) => results.length > 1 || scheme.isFailingLetter(results.single.grade))
      .length;
  if (count == 0) return null;

  final institution = nigerianInstitutions.firstWhereOrNull((i) => i.id == scheme.institutionId);
  final institutionName = institution?.name ?? scheme.name;

  final body = switch (scheme.repeatPolicy) {
    RepeatPolicy.countBothAttempts =>
      "Both attempts count under $institutionName's rules, so clearing these lifts your CGPA twice over.",
    RepeatPolicy.replaceOriginal => 'Clearing these replaces the original grade.',
    RepeatPolicy.replaceWithCap =>
      'Retakes cap at ${scheme.repeatCapPoint?.toStringAsFixed(1) ?? '—'} points.',
  };

  return Insight(
    kind: InsightKind.carryovers,
    title: 'You have $count outstanding carryover${count == 1 ? '' : 's'}',
    body: body,
    warning: scheme.isVerified
        ? null
        : "We haven't confirmed ${institution?.abbreviation ?? scheme.name}'s carryover rule — "
            'check with your department.',
  );
}

/// Whether a semester before the student's current level is missing,
/// reusing the same derivation as the Backfill screen — never a fixed
/// 100-600 range.
Insight? _nextEntryInsight(
  List<Semester> rawSemesters,
  GradingScheme scheme,
  StudentProfile? profile,
) {
  if (profile == null || rawSemesters.isEmpty) return null;

  final expected = expectedSemesterKeys(
    currentLevel: profile.currentLevel,
    existingSemesters: rawSemesters,
  );
  final missing = expected
      .where((key) => !rawSemesters.any((s) => s.level == key.level && s.term == key.term))
      .toList()
    ..sort((a, b) => (a.level * 10 + a.term.index).compareTo(b.level * 10 + b.term.index));
  if (missing.isEmpty) return null;

  final earliest = missing.first;
  final last = rawSemesters.reduce((a, b) => a.sortKey > b.sortKey ? a : b);

  return Insight(
    kind: InsightKind.nextEntry,
    title: 'Add your ${earliest.level}L ${scheme.termLabel(earliest.term)} results',
    body: 'Your record stops at ${last.level}L ${scheme.termLabel(last.term)}.',
  );
}

Insight _insufficientDataInsight() => const Insight(
      kind: InsightKind.insufficientData,
      title: 'Add more semesters for a sharper read',
      body: 'With one semester we can compute what you need, but not how it '
          'compares to your usual performance.',
    );

/// The payload sent to the `ai-advisor` Edge Function as chat "context" --
/// the chat counterpart to this file's insight cards, built from the exact
/// same already-computed [AdvisorState]/[AcademicStanding]/[TargetProjection]
/// rather than anything re-derived. Per AGENTS.md's "THE RULE THAT MATTERS
/// MOST", the model receives these computed facts and phrases them; it is
/// never given [rawSemesters] or any per-course grade to reason about
/// itself, which is why this function's signature doesn't even accept them.
Map<String, dynamic> buildAdvisorChatContext({
  required AdvisorState state,
  required AcademicStanding standing,
  required StudentProfile? profile,
  required ClassificationBand? goalBand,
  required TargetProjection? goalProjection,
}) {
  return {
    'has_data': state.hasData,
    'is_critical': state.isCritical,
    'cgpa': state.hasData ? standing.cgpa : null,
    'classification_label': standing.classification?.label,
    'level': profile?.currentLevel,
    'department': profile?.department,
    'faculty': profile?.faculty,
    'semesters_recorded': standing.semesters.length,
    'best_semester_gpa': standing.bestSemesterGpa,
    'recent_trend_delta': standing.recentTrend(),
    'goal_classification_label': goalBand?.label,
    'goal_projection': goalProjection?.toAdvisorPayload(),
    'critical_standing': state.critical == null
        ? null
        : {
            'cgpa': state.critical!.cgpa,
            'institution_name': state.critical!.institutionName,
            'lowest_classification_label': state.critical!.lowestBand.label,
            'projection_to_lowest_classification': state.critical!.projectionToLowestBand.toAdvisorPayload(),
          },
    'insight_cards': state.insights
        .map((i) => {'kind': i.kind.name, 'title': i.title, 'body': i.body})
        .toList(),
  };
}

/// Deterministic phrasing of [TargetProjection.toAdvisorPayload()] into the
/// AI Advisor's copy.
///
/// TODO(v2): replace this template with real LLM prose via the AI
/// Orchestration backend proxy. The model must still be fed only this
/// payload — never raw grades — per AGENTS.md's core rule: the LLM never
/// performs arithmetic.
library;

import '../../../domain/engine/projection_solver.dart';

class AdvisorInsight {
  final String headline;
  final List<String> keyInsights;

  const AdvisorInsight({required this.headline, required this.keyInsights});
}

AdvisorInsight buildAdvisorInsight(TargetProjection projection) {
  final target = projection.targetLabel ?? 'your target';

  final headline = switch (projection.feasibility) {
    Feasibility.secured => 'You\'ve already secured $target.',
    Feasibility.comfortable => 'You are on track for $target if you keep up your current average.',
    Feasibility.withinReach => 'You are on track for $target if you maintain strong performance.',
    Feasibility.demanding => '$target is within reach, but it will take a real push.',
    Feasibility.extremelyDemanding => '$target requires near-perfect grades from here.',
    Feasibility.unreachable => '$target is no longer reachable from your current standing.',
  };

  final insights = <String>[];

  if (projection.requiredAverage != null) {
    insights.add(
      'You need an average of ${projection.requiredAverage!.toStringAsFixed(2)} '
      'across your remaining ${projection.creditsRemaining} credit units.',
    );
  }

  if (projection.personalBest != null) {
    insights.add(
      projection.requiredAverage != null && projection.requiredAverage! > projection.personalBest!
          ? 'That is above your best semester so far (${projection.personalBest!.toStringAsFixed(2)}).'
          : 'That is within reach of your best semester so far (${projection.personalBest!.toStringAsFixed(2)}).',
    );
  }

  insights.add(
    '${projection.semestersRemaining} semester${projection.semestersRemaining == 1 ? '' : 's'} remaining.',
  );

  if (!projection.isReachable && projection.nearestAchievable != null) {
    insights.add('The best still within reach is ${projection.nearestAchievable!.label}.');
  }

  return AdvisorInsight(headline: headline, keyInsights: insights);
}

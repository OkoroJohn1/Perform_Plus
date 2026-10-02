/// The required-pace strip — the single most actionable number on the
/// dashboard: what average does the next semester actually need to be?
/// Always the *solved* value from [ProjectionSolver.solveForTarget], never
/// a classification threshold. Hidden entirely when there's no goal, or
/// when the goal is already secured (nothing left to pace toward).
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/engine/projection_solver.dart';

String _fmt(double v) => v.toStringAsFixed(2);

/// On-white-card feasibility colours — distinct from the pale ring variants
/// in `cgpa_card.dart`, which are tuned for the hero's dark gradient fill.
extension _StripPresentation on Feasibility {
  Color get color => switch (this) {
        Feasibility.secured || Feasibility.comfortable => FeasibilityPalette.secured,
        Feasibility.withinReach => FeasibilityPalette.withinReach,
        Feasibility.demanding => FeasibilityPalette.demanding,
        Feasibility.extremelyDemanding => FeasibilityPalette.extremelyDemanding,
        Feasibility.unreachable => FeasibilityPalette.unreachable,
      };
}

class RequiredPaceStrip extends StatelessWidget {
  final TargetProjection goal;
  final String bandShortLabel;

  const RequiredPaceStrip({super.key, required this.goal, required this.bandShortLabel});

  @override
  Widget build(BuildContext context) {
    final required = goal.requiredAverage;
    if (required == null) return const SizedBox.shrink();

    final color = goal.feasibility.color;
    final n = goal.semestersRemaining;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.speed_outlined, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average ${_fmt(required)} per semester',
                  style: TextStyle(
                    color: context.palette.bodyText,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'for $n more semester${n == 1 ? '' : 's'} to reach $bandShortLabel',
                  style: TextStyle(
                    color: context.palette.secondaryText,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

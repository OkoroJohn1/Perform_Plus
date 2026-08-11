/// CGPA card — current standing plus goal progress ring.
///
/// The ring never fabricates a probability. It plots [currentCgpa] against
/// [TargetProjection.targetCgpa], and the status line underneath is the
/// engine's own [Feasibility] label, not an invented percentage.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/engine/projection_solver.dart';
import '../../../shared/widgets/glass_card.dart';

class CgpaCard extends StatelessWidget {
  final AcademicStanding standing;
  final TargetProjection? goal;
  final VoidCallback onSetGoal;

  const CgpaCard({
    super.key,
    required this.standing,
    required this.goal,
    required this.onSetGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current CGPA',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    standing.cgpa.toStringAsFixed(2),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    standing.classification?.label ?? 'Not yet classified',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _GoalRing(goal: goal, onSetGoal: onSetGoal),
          ],
        ),
      ),
    );
  }
}

class _GoalRing extends StatelessWidget {
  final TargetProjection? goal;
  final VoidCallback onSetGoal;

  const _GoalRing({required this.goal, required this.onSetGoal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goal = this.goal;

    if (goal == null) {
      return InkWell(
        onTap: onSetGoal,
        borderRadius: BorderRadius.circular(44),
        child: SizedBox(
          width: 88,
          height: 88,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag_outlined, color: scheme.primary),
              const SizedBox(height: 4),
              Text(
                'Set a\ngoal',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    // Coasting to a secured target still reads as full progress — the
    // student has already cleared the bar, not merely approached it.
    final progress = goal.feasibility == Feasibility.secured
        ? 1.0
        : (goal.currentCgpa / goal.targetCgpa).clamp(0.0, 1.0);

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: 30,
              sections: [
                PieChartSectionData(
                  value: progress * 100,
                  color: scheme.primary,
                  radius: 10,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: (1 - progress) * 100,
                  color: scheme.surfaceContainerHighest,
                  radius: 10,
                  showTitle: false,
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                goal.feasibility.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

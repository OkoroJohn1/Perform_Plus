/// Next-action card.
///
/// The message is derived from the engine's own outputs — excluded
/// results, semester count, projection feasibility — never a generic
/// placeholder, so the "one next action" promise stays honest.
library;

import 'package:flutter/material.dart';

import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/engine/projection_solver.dart';

class NextActionCard extends StatelessWidget {
  final AcademicStanding standing;
  final TargetProjection? goal;
  final VoidCallback onTap;

  const NextActionCard({
    super.key,
    required this.standing,
    required this.goal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = _resolve();

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: action.warning
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.primaryContainer,
          child: Icon(
            action.icon,
            color: action.warning
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(action.title, style: theme.textTheme.titleSmall),
        subtitle: Text(action.subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  _NextAction _resolve() {
    if (standing.hasErrors) {
      final count = standing.issues
          .where((i) => i.severity == IssueSeverity.error)
          .length;
      return _NextAction(
        icon: Icons.error_outline,
        title: 'Review needed',
        subtitle:
            "$count result${count == 1 ? '' : 's'} weren't counted — see why",
        warning: true,
      );
    }

    if (standing.semesters.length < 2) {
      return const _NextAction(
        icon: Icons.add_chart,
        title: 'Add your next semester',
        subtitle: 'Two semesters unlock your CGPA trend.',
      );
    }

    final goal = this.goal;
    if (goal != null && goal.isReachable) {
      if (goal.feasibility == Feasibility.secured) {
        return _NextAction(
          icon: Icons.flag,
          title: 'Goal secured',
          subtitle: 'You\'ve already met ${goal.targetLabel}. Keep going.',
        );
      }
      return _NextAction(
        icon: Icons.trending_up,
        title: 'Stay on target',
        subtitle: 'You need a ${goal.requiredAverage?.toStringAsFixed(2)} '
            'average for ${goal.targetLabel} from here.',
      );
    }

    return const _NextAction(
      icon: Icons.add_chart,
      title: 'Add your next semester',
      subtitle: 'Keep your record up to date as results land.',
    );
  }
}

class _NextAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool warning;

  const _NextAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.warning = false,
  });
}

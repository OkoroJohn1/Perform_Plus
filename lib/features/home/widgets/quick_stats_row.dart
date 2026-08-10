import 'package:flutter/material.dart';

import '../../../domain/engine/cgpa_engine.dart';
import '../../../shared/widgets/stat_tile.dart';

class QuickStatsRow extends StatelessWidget {
  final AcademicStanding standing;

  const QuickStatsRow({super.key, required this.standing});

  @override
  Widget build(BuildContext context) {
    final best = standing.bestSemesterGpa;
    return Row(
      children: [
        Expanded(
          child: StatTile(
            label: 'Best semester',
            value: best == null ? '—' : best.toStringAsFixed(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatTile(
            label: 'Credit units',
            value: '${standing.totalCreditUnits}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatTile(
            label: 'Classification',
            value: standing.classification?.shortLabel ?? '—',
          ),
        ),
      ],
    );
  }
}

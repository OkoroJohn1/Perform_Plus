import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/engine/projection_solver.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/providers/profile_provider.dart';

class RoadmapView extends ConsumerWidget {
  const RoadmapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standing = ref.watch(standingProvider);
    final profile = ref.watch(studentProfileProvider);

    if (!standing.hasData) {
      return const EmptyState(
        icon: Icons.timeline_outlined,
        title: 'No roadmap yet',
        message: 'Add results to see your progress across levels.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Level roadmap',
            action: 'Simulate Future',
            onAction: () => _showSimulateSheet(context, ref, standing),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                for (final level in AppConstants.levels)
                  _LevelStep(
                    level: level,
                    semesters:
                        standing.semesters.where((s) => s.level == level).toList(),
                    isCurrent: profile?.currentLevel == level,
                    isLast: level == AppConstants.levels.last,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSimulateSheet(BuildContext context, WidgetRef ref, AcademicStanding standing) {
    final scheme = ref.read(academicRecordProvider).scheme;
    var assumedGpa = standing.cgpa;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final projection = ProjectionSolver.simulate(
            standing: standing,
            scheme: scheme,
            assumedGpa: assumedGpa,
            semestersRemaining: 1,
          );
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Simulate future', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'If your next semester GPA is ${assumedGpa.toStringAsFixed(2)}:',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Slider(
                    value: assumedGpa.clamp(0, scheme.maxPoint),
                    min: 0,
                    max: scheme.maxPoint,
                    divisions: (scheme.maxPoint * 20).round(),
                    label: assumedGpa.toStringAsFixed(2),
                    onChanged: (v) => setState(() => assumedGpa = v),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Projected CGPA: ${projection.projectedCgpa.toStringAsFixed(2)}'
                    '${projection.projectedClassification != null ? ' (${projection.projectedClassification!.shortLabel})' : ''}',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    projection.deltaFromCurrent >= 0
                        ? 'Up ${projection.deltaFromCurrent.toStringAsFixed(2)} from your current CGPA'
                        : 'Down ${(-projection.deltaFromCurrent).toStringAsFixed(2)} from your current CGPA',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LevelStep extends StatelessWidget {
  final int level;
  final List<SemesterComputation> semesters;
  final bool isCurrent;
  final bool isLast;

  const _LevelStep({
    required this.level,
    required this.semesters,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = semesters.isNotEmpty;
    final color = done
        ? theme.colorScheme.primary
        : (isCurrent ? theme.colorScheme.tertiary : theme.colorScheme.outline);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.circle_outlined,
                color: color,
                size: 20,
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: theme.colorScheme.outlineVariant)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$level Level',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: isCurrent ? FontWeight.w700 : null,
                    ),
                  ),
                  Text(
                    semesters.isEmpty
                        ? (isCurrent ? 'Current' : 'Upcoming')
                        : semesters.map((s) => s.gpa.toStringAsFixed(2)).join(' / '),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

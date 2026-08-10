/// Goal setting — the emotional core.
///
/// Turns a calculator into an advisor: every later screen is framed against
/// the answer given here. Handles the impossible case with care — a
/// low-standing student targeting First Class hears it is out of reach
/// ONCE, then is pivoted immediately to [TargetProjection.nearestAchievable].
/// Never a red error state, never a fabricated percentage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/repositories/goal_provider.dart';
import '../../../domain/engine/projection_solver.dart';
import '../../../domain/models/grading_scheme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/providers/profile_provider.dart';

class GoalSettingScreen extends ConsumerStatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  ConsumerState<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends ConsumerState<GoalSettingScreen> {
  ClassificationBand? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final standing = ref.watch(standingProvider);
    final scheme = ref.watch(academicRecordProvider).scheme;
    final profile = ref.watch(studentProfileProvider);

    if (!standing.hasData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Set your goal')),
        body: EmptyState(
          icon: Icons.flag_outlined,
          title: 'Add results first',
          message: 'Your goal is measured against your own results — add at least one semester first.',
          actionLabel: 'Add your results',
          onAction: () => context.go(Routes.addFirstResults),
        ),
      );
    }

    final semestersRemaining =
        profile != null ? semestersRemainingFor(profile) : 0;

    final projections = ProjectionSolver.allBandProjections(
      standing: standing,
      scheme: scheme,
      semestersRemaining: semestersRemaining,
    );

    final selectedProjection = projections.firstWhere(
      (p) => p.targetLabel == (_selected ?? scheme.bandsDescending.first).label,
      orElse: () => projections.first,
    );

    final trajectory = ProjectionSolver.simulate(
      standing: standing,
      scheme: scheme,
      assumedGpa: standing.cgpa,
      semestersRemaining: semestersRemaining,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Set your goal')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("What's your goal?", style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Target classification',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ClassificationBand>(
                initialValue: scheme.bandsDescending.firstWhere(
                  (b) => b.label == selectedProjection.targetLabel,
                  orElse: () => scheme.bandsDescending.first,
                ),
                items: scheme.bandsDescending
                    .map((b) => DropdownMenuItem(value: b, child: Text(b.label)))
                    .toList(),
                onChanged: (b) => setState(() => _selected = b),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: selectedProjection.isReachable
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedProjection.requiredAverage == null
                                  ? 'Your record is already final.'
                                  : 'You need an average of '
                                      '${selectedProjection.requiredAverage!.toStringAsFixed(2)} '
                                      'GPA to achieve this.',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedProjection.feasibility.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${selectedProjection.targetLabel} is not reachable '
                              'from here.',
                              style: theme.textTheme.titleSmall,
                            ),
                            if (selectedProjection.nearestAchievable != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'The best you can still reach is '
                                '${selectedProjection.nearestAchievable!.label}.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ],
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your current trajectory',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trajectory.projectedCgpa.toStringAsFixed(2)} CGPA',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'if you maintain your current ${standing.cgpa.toStringAsFixed(2)} average',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  final band = _selected ??
                      scheme.bandsDescending.firstWhere(
                        (b) => b.label == selectedProjection.targetLabel,
                      );
                  ref.read(goalProvider.notifier).state = GoalTarget(
                    band: band,
                    semestersRemaining: semestersRemaining,
                  );
                  context.go(Routes.addFirstResults);
                },
                child: const Text('Save Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

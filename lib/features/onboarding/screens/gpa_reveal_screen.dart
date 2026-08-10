/// GPA reveal — the payoff after entering results.
///
/// Reached near the end of onboarding (after sign-in, profile, backfill and
/// goal setting), once the student has added their first semester. Landing
/// here confirms their goal against real numbers before they reach the
/// dashboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../providers/onboarding_provider.dart';

class GpaRevealScreen extends ConsumerWidget {
  const GpaRevealScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final computation = ref.watch(draftComputationProvider);
    final draft = ref.watch(onboardingDraftProvider);

    if (computation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Your ${computation.shortLabel} GPA',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.14),
                      theme.colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Text(
                  computation.gpa.toStringAsFixed(2),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${computation.creditUnits} credit units  |  '
                '${computation.qualityPoints.toStringAsFixed(0)} quality points',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // "Show the math" builds trust in the number. A student who
              // can verify the calculation will trust the projections later.
              ExpansionTile(
                title: const Text('Show the calculation'),
                tilePadding: EdgeInsets.zero,
                children: [
                  ...draft.committed!.results.map((r) {
                    final point = draft.scheme.pointForLetter(r.grade) ?? 0;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(r.courseCode),
                      subtitle: Text(
                        '${r.creditUnit} units x $point (${r.grade})',
                      ),
                      trailing: Text(
                        (point * r.creditUnit).toStringAsFixed(0),
                        style: theme.textTheme.titleSmall,
                      ),
                    );
                  }),
                  const Divider(),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Total'),
                    subtitle: Text(
                      '${computation.qualityPoints.toStringAsFixed(0)} / '
                      '${computation.creditUnits}',
                    ),
                    trailing: Text(
                      computation.gpa.toStringAsFixed(2),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),

              if (computation.excluded.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Not counted',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        ...computation.excluded.map((e) => Text(
                              '${e.courseCode} — ${e.reason}',
                              style: theme.textTheme.bodySmall,
                            )),
                      ],
                    ),
                  ),
                ),
              ],

              const Spacer(),
              FilledButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Continue to my dashboard'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(Routes.addFirstResults),
                child: const Text('Add another semester first'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

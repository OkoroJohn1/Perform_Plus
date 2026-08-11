/// GPA reveal — the Act 1 payoff.
///
/// This screen is why the signup gate sits AFTER it rather than before.
/// The student now has something to lose, which converts far better than
/// a toll gate placed in front of an unproven promise.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../providers/onboarding_provider.dart';

class GpaRevealScreen extends ConsumerWidget {
  const GpaRevealScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final computation = ref.watch(draftComputationProvider);
    final draft = ref.watch(onboardingDraftProvider);

    if (computation == null) {
      return const GradientScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GradientScaffold(
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
                GlassCard(
                  tint: theme.colorScheme.error,
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
              ],

              const Spacer(),
              GradientButton(
                onPressed: () => context.go(Routes.signIn),
                child: const Text('Save this and track my CGPA'),
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

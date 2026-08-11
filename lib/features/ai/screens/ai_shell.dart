/// AI Advisor (V1). AI Assistant Chat is V2 — deliberately omitted rather
/// than shown as a locked composer, which would read as broken.
///
/// The advisor never performs arithmetic; it phrases the engine's own
/// [TargetProjection] via [buildAdvisorInsight], never raw grades. See
/// AGENTS.md's "THE RULE THAT MATTERS MOST".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/repositories/goal_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../services/advisor_template.dart';

class AiShell extends ConsumerWidget {
  const AiShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projection = ref.watch(targetProjectionProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text('AI Advisor')),
      body: projection == null
          ? EmptyState(
              icon: Icons.auto_awesome_outlined,
              title: 'Set a goal to get advisor insights',
              message: 'The advisor compares your standing against a real target — set one to see it.',
              actionLabel: 'Set your goal',
              onAction: () => context.go(Routes.goalSetting),
            )
          : Builder(builder: (context) {
              final insight = buildAdvisorInsight(projection);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      tint: theme.colorScheme.primary,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Advisor Insight',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            insight.headline,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Key Insights', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...insight.keyInsights.map(
                      (line) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(child: Text(line)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
    );
  }
}

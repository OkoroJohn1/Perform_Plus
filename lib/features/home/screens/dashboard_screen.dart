/// Dashboard — the Act 3 landing screen.
///
/// Three states, driven entirely by [standingProvider]
/// (`CgpaEngine.computeStanding`), never by a loading flag:
///   * empty   — no results at all.
///   * partial — one semester. A single point can't draw a trend, so the
///     chart is swapped for a placeholder while the rest of the dashboard
///     renders normally.
///   * full    — two or more semesters. Trend chart, quick stats, goal
///     ring and next action all have real data.
///
/// Notifications live as a bell in this header, not a tab — nobody
/// navigates to notifications, they respond to a badge.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/repositories/goal_provider.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../widgets/cgpa_card.dart';
import '../widgets/next_action_card.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/trend_chart.dart';
import 'notifications_panel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standing = ref.watch(standingProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _DashboardHeader(),
            Expanded(
              child: standing.hasData
                  ? _PopulatedDashboard(standing: standing)
                  : const _EmptyDashboard(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authStateProvider).valueOrNull;
    final standing = ref.watch(standingProvider);
    final goal = ref.watch(goalProvider);
    final read = ref.watch(notificationsReadProvider);
    final hasAlert = standing.hasErrors || goal == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_greeting()}, ${_firstName(auth?.email)}',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Badge(
            isLabelVisible: hasAlert && !read,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed: () => showNotificationsPanel(context),
            ),
          ),
        ],
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _firstName(String? email) {
    if (email == null || email.isEmpty) return 'there';
    final local = email.split('@').first;
    if (local.isEmpty) return 'there';
    return local[0].toUpperCase() + local.substring(1);
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.query_stats_outlined,
      title: 'Nothing here yet',
      message:
          'Add a semester of results and your CGPA, trend and goal progress will show up here.',
      actionLabel: 'Add your first results',
      onAction: () => context.go(Routes.academics),
    );
  }
}

class _PopulatedDashboard extends ConsumerWidget {
  final AcademicStanding standing;

  const _PopulatedDashboard({required this.standing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final goal = ref.watch(targetProjectionProvider);
    final scheme = ref.watch(academicRecordProvider).scheme;
    final isPartial = standing.semesters.length < 2;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CgpaCard(
          standing: standing,
          goal: goal,
          onSetGoal: () => context.go(Routes.goalSetting),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CGPA trend', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                isPartial
                    ? const TrendPlaceholder()
                    : TrendChart(standing: standing, maxPoint: scheme.maxPoint),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        QuickStatsRow(standing: standing),
        const SizedBox(height: 16),
        NextActionCard(
          standing: standing,
          goal: goal,
          onTap: () => context.go(Routes.academics),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/academic_record_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/locked_feature_row.dart';
import '../../../shared/widgets/section_header.dart';

class ReportsView extends ConsumerWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standing = ref.watch(standingProvider);

    if (!standing.hasData) {
      return const EmptyState(
        icon: Icons.description_outlined,
        title: 'No reports yet',
        message: 'Add results to generate an academic summary.',
      );
    }

    final trend = standing.recentTrend();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Reports',
            action: 'Generate New Report',
            onAction: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report generation isn\'t available yet.')),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _ReportCard(
                  icon: Icons.summarize_outlined,
                  title: 'Academic Summary',
                  subtitle: 'Overall academic performance',
                  body:
                      '${standing.cgpa.toStringAsFixed(2)} CGPA — '
                      '${standing.classification?.label ?? 'Not yet classified'}\n'
                      '${standing.totalCreditUnits} total credit units',
                ),
                _ReportCard(
                  icon: Icons.bar_chart_outlined,
                  title: 'Semester Analysis',
                  subtitle: 'Detailed semester breakdown',
                  body: 'Best semester: ${standing.bestSemesterGpa?.toStringAsFixed(2) ?? '—'}\n'
                      'Weakest semester: ${standing.worstSemesterGpa?.toStringAsFixed(2) ?? '—'}',
                ),
                _ReportCard(
                  icon: Icons.trending_up,
                  title: 'Performance Over Time',
                  subtitle: 'Trends and improvements',
                  body: trend == null
                      ? 'Add another semester to see a trend.'
                      : trend >= 0
                          ? 'Up ${trend.toStringAsFixed(2)} over your recent semesters'
                          : 'Down ${(-trend).toStringAsFixed(2)} over your recent semesters',
                ),
                const SizedBox(height: 8),
                const LockedFeatureRow(
                  icon: Icons.insights_outlined,
                  title: 'Strength Analysis',
                  subtitle: 'Per-course strengths and areas to improve',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text(body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reports — rebuilt onto the same light `#F7F7FB`/`OnboardingLightPalette`
/// surface as the rest of the Academics tab (see `results_view.dart`).
///
/// ⚠ FIXED: like `roadmap_view.dart`, this screen used to read
/// `Theme.of(context)` and `GlassCard` (tuned for the app's old dark-glass
/// theme) while sitting on `academics_shell.dart`'s light background --
/// producing dim, low-contrast text and cards that didn't match the rest of
/// the tab. Every colour here is hardcoded to `OnboardingLightPalette`.
///
/// PDF export isn't wired up yet (see AGENTS.md) -- "Generate report" stays
/// an honest, clearly-labelled stub rather than a button that silently does
/// nothing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/academic_record_provider.dart';

class ReportsView extends ConsumerWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standing = ref.watch(standingProvider);

    if (!standing.hasData) {
      return const _EmptyReports();
    }

    final trend = standing.recentTrend();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Reports',
                style: TextStyle(color: context.palette.bodyText, fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            _GenerateReportButton(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Report export isn't available yet.")),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'A plain-language summary of your record',
          style: TextStyle(color: context.palette.secondaryText, fontSize: 14.5),
        ),
        const SizedBox(height: 20),
        _ReportCard(
          icon: Icons.summarize_outlined,
          iconColor: context.palette.primary,
          title: 'Academic Summary',
          subtitle: 'Overall academic performance',
          rows: [
            (label: 'CGPA', value: standing.cgpa.toStringAsFixed(2)),
            (label: 'Classification', value: standing.classification?.label ?? 'Not yet classified'),
            (label: 'Total credit units', value: '${standing.totalCreditUnits}'),
          ],
        ),
        const SizedBox(height: 16),
        _ReportCard(
          icon: Icons.bar_chart_outlined,
          iconColor: context.palette.success,
          title: 'Semester Analysis',
          subtitle: 'Detailed semester breakdown',
          rows: [
            (label: 'Best semester', value: standing.bestSemesterGpa?.toStringAsFixed(2) ?? '—'),
            (label: 'Weakest semester', value: standing.worstSemesterGpa?.toStringAsFixed(2) ?? '—'),
          ],
        ),
        const SizedBox(height: 16),
        _ReportCard(
          icon: trend == null ? Icons.timeline_outlined : (trend >= 0 ? Icons.trending_up : Icons.trending_down),
          iconColor: trend == null
              ? context.palette.secondaryText
              : (trend >= 0 ? context.palette.success : context.palette.amber),
          title: 'Performance Over Time',
          subtitle: 'Trends and improvements',
          rows: [
            (
              label: 'Recent trend',
              value: trend == null
                  ? 'Add another semester to see a trend'
                  : trend >= 0
                      ? 'Up ${trend.toStringAsFixed(2)}'
                      : 'Down ${(-trend).toStringAsFixed(2)}',
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _LockedReportRow(
          icon: Icons.insights_outlined,
          title: 'Strength Analysis',
          subtitle: 'Per-course strengths and areas to improve',
        ),
      ],
    );
  }
}

class _GenerateReportButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GenerateReportButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.palette.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_outlined, size: 16, color: context.palette.primary),
            const SizedBox(width: 6),
            Text(
              'Generate',
              style: TextStyle(color: context.palette.primary, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<({String label, String value})> rows;

  const _ReportCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 21, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: context.palette.bodyText, fontSize: 16.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: context.palette.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFECECF1)),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(rows[i].label, style: TextStyle(color: context.palette.secondaryText, fontSize: 14)),
                Flexible(
                  child: Text(
                    rows[i].value,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: context.palette.bodyText, fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LockedReportRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LockedReportRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
      ),
      child: Opacity(
        opacity: 0.6,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.palette.secondaryText.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: context.palette.secondaryText),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: context.palette.bodyText, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(color: context.palette.secondaryText, fontSize: 12.5)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.palette.secondaryText.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'V2',
                style: TextStyle(color: context.palette.secondaryText, fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined, size: 48, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              'No reports yet',
              style: TextStyle(color: context.palette.bodyText, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Add results to generate an academic summary.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.secondaryText, fontSize: 15.5),
            ),
          ],
        ),
      ),
    );
  }
}

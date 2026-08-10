/// CGPA trend chart.
///
/// Plots [AcademicStanding.cumulativeCgpaTrend] — running CGPA-to-date
/// after each semester, not the raw per-semester GPA. One data point can't
/// draw a trend, so callers must not render this for fewer than two
/// semesters; see [TrendPlaceholder] for that case.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../domain/engine/cgpa_engine.dart';

class TrendChart extends StatelessWidget {
  final AcademicStanding standing;
  final double maxPoint;

  const TrendChart({super.key, required this.standing, required this.maxPoint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trend = standing.cumulativeCgpaTrend;
    final labels = standing.semesters.map((s) => s.shortLabel).toList();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxPoint,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxPoint / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: scheme.outlineVariant, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: maxPoint / 4,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[i],
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      s.y.toStringAsFixed(2),
                      TextStyle(color: scheme.onInverseSurface),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < trend.length; i++)
                  FlSpot(i.toDouble(), trend[i]),
              ],
              isCurved: true,
              color: scheme.primary,
              barWidth: 3,
              dotData: FlDotData(
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: scheme.primary,
                  strokeWidth: 2,
                  strokeColor: scheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: scheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown in place of the chart when there's exactly one semester — a
/// single point has no trend to draw, but it isn't an error state either.
class TrendPlaceholder extends StatelessWidget {
  const TrendPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 160,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart, color: theme.colorScheme.outline),
              const SizedBox(height: 8),
              Text(
                'Add another semester to see your trend',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

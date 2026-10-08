/// Full-screen CGPA trend breakdown — opened by tapping the Dashboard's
/// `TrendCard`. A bigger, single-touch-interactive version of the same
/// chart (drag across it to inspect one point at a time, rather than the
/// card's always-show-everything tooltips) plus a scrollable per-semester
/// breakdown list underneath, over a blurred dashboard background.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/performance_flag.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/engine/projection_solver.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';
import '../../../shared/widgets/spin_pop_dialog.dart';
import 'trend_chart.dart';

String _fmt(double v) => v.toStringAsFixed(2);

Future<void> showTrendDetail(
  BuildContext context, {
  required AcademicStanding standing,
  required GradingScheme scheme,
  required List<Semester> rawSemesters,
  required TargetProjection? goal,
}) {
  return showSpinPopDetail(
    context,
    builder: (context) => _TrendDetailOverlay(
      standing: standing,
      scheme: scheme,
      rawSemesters: rawSemesters,
      goal: goal,
    ),
  );
}

class _TrendDetailOverlay extends StatelessWidget {
  final AcademicStanding standing;
  final GradingScheme scheme;
  final List<Semester> rawSemesters;
  final TargetProjection? goal;

  const _TrendDetailOverlay({
    required this.standing,
    required this.scheme,
    required this.rawSemesters,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      fit: StackFit.expand,
      children: [
        const SpinPopScrim(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 40, offset: const Offset(0, 16)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              // `showGeneralDialog` renders this panel in the Navigator's
              // Overlay, outside any `Material`/`Scaffold` ancestor -- so
              // every Text here fell back to Flutter's debug "no Material
              // ancestor" style, a jarring double underline, which only
              // ever showed up because nothing before this wrapped the
              // panel in a `Material` of its own. One `Material` here
              // fixes every Text inside it at once.
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'CGPA trend',
                            style: TextStyle(color: palette.bodyText, fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('trendDetailCloseTap'),
                          icon: Icon(Icons.close, color: palette.secondaryText),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Drag across the chart to inspect a point.',
                      style: TextStyle(color: palette.secondaryText, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: 280,
                      child: _InteractiveTrendChart(standing: standing, scheme: scheme, goal: goal),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: palette.divider),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      itemCount: standing.semesters.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: palette.divider),
                      itemBuilder: (context, i) {
                        // Oldest first on the chart's x-axis, so list the
                        // same way rather than reversing -- the two must
                        // agree on order or "point 3" on the chart
                        // wouldn't match row 3 in the list below it.
                        final comp = standing.semesters[i];
                        final cgpaThen = standing.cumulativeCgpaTrend[i];
                        final courseCount = rawSemesters
                            .firstWhere((s) => s.id == comp.semesterId, orElse: () => rawSemesters[i])
                            .results
                            .length;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: palette.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${comp.level}L',
                                  style: TextStyle(color: palette.primary, fontSize: 12.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${shortTermLabel(scheme, comp.term)} · $courseCount courses',
                                      style: TextStyle(color: palette.bodyText, fontSize: 14.5, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'GPA ${_fmt(comp.gpa)}',
                                      style: TextStyle(color: palette.secondaryText, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _fmt(cgpaThen),
                                style: TextStyle(
                                  color: performanceColor(cgpaThen, normal: palette.bodyText),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InteractiveTrendChart extends StatelessWidget {
  final AcademicStanding standing;
  final GradingScheme scheme;
  final TargetProjection? goal;

  const _InteractiveTrendChart({required this.standing, required this.scheme, required this.goal});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final trend = standing.cumulativeCgpaTrend;
    final maxPoint = scheme.maxPoint;
    final spots = [for (var i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i])];

    final rangeAnnotations = RangeAnnotations(
      horizontalRangeAnnotations: [
        for (final band in scheme.classifications)
          if (band.minCgpa < maxPoint)
            HorizontalRangeAnnotation(
              y1: band.minCgpa.clamp(0, maxPoint),
              y2: (band.maxCgpa > maxPoint ? maxPoint : band.maxCgpa).toDouble(),
              color: ClassificationPalette.colorForBandIndex(
                scheme.bandsDescending.indexWhere((b) => b.label == band.label),
              ).withValues(alpha: 0.05),
            ),
      ],
    );

    final extraLinesData = ExtraLinesData(
      horizontalLines: [
        for (final band in scheme.bandsDescending)
          if (band.minCgpa > 0 && band.minCgpa < maxPoint)
            HorizontalLine(
              y: band.minCgpa,
              strokeWidth: 0,
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => band.shortLabel,
                style: TextStyle(fontSize: 11, color: palette.hintText),
              ),
            ),
        if (goal != null)
          HorizontalLine(
            y: goal!.targetCgpa,
            color: palette.primary.withValues(alpha: 0.5),
            strokeWidth: 1.5,
            dashArray: const [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topLeft,
              labelResolver: (_) => 'Goal ${_fmt(goal!.targetCgpa)}',
              style: TextStyle(fontSize: 11.5, color: palette.primary.withValues(alpha: 0.8)),
            ),
          ),
      ],
    );

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxPoint,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border(bottom: BorderSide(color: palette.divider, width: 1)),
        ),
        rangeAnnotations: rangeAnnotations,
        extraLinesData: extraLinesData,
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= standing.semesters.length) return const SizedBox();
                final comp = standing.semesters[i];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${comp.level}L ${shortTermLabel(scheme, comp.term)}',
                    style: TextStyle(color: palette.secondaryText, fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.28,
            barWidth: 3.5,
            gradient: LinearGradient(colors: [palette.primaryGradientStart, palette.primary]),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.primary.withValues(alpha: 0.18), palette.primary.withValues(alpha: 0.0)],
              ),
            ),
            dotData: FlDotData(
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4.5,
                color: palette.surface,
                strokeWidth: 2.5,
                strokeColor: palette.primary,
              ),
            ),
          ),
        ],
        // Only the finger-touched point shows a tooltip here -- the
        // dashboard card's smaller version deliberately shows every point
        // at once; this detail view is specifically for dragging across
        // to inspect one point at a time.
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => palette.bodyText.withValues(alpha: 0.92),
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final i = spot.x.round();
              if (i < 0 || i >= standing.semesters.length) return null;
              final comp = standing.semesters[i];
              return LineTooltipItem(
                '${comp.level}L ${shortTermLabel(scheme, comp.term)}\n',
                TextStyle(color: palette.surface, fontSize: 11, fontWeight: FontWeight.w600),
                children: [
                  TextSpan(
                    text: 'CGPA ${_fmt(spot.y)}',
                    style: TextStyle(color: palette.surface, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
      duration: Duration.zero,
    );
  }
}

/// CGPA trend card.
///
/// Plots [AcademicStanding.cumulativeCgpaTrend] — running CGPA-to-date
/// after each semester, never the raw per-semester GPA. One data point
/// can't draw a trend, so callers must not render the chart for fewer than
/// two semesters; see [TrendPlaceholder] for that case.
///
/// Classification bands drawn behind the line, and the optional goal line,
/// both read straight from [GradingScheme] / [TargetProjection] — nothing
/// here is a hardcoded threshold.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/engine/projection_solver.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';

String _fmt(double v) => v.toStringAsFixed(2);

extension _StripPresentation on Feasibility {
  Color get color => switch (this) {
        Feasibility.secured || Feasibility.comfortable => FeasibilityPalette.secured,
        Feasibility.withinReach => FeasibilityPalette.withinReach,
        Feasibility.demanding => FeasibilityPalette.demanding,
        Feasibility.extremelyDemanding => FeasibilityPalette.extremelyDemanding,
        Feasibility.unreachable => FeasibilityPalette.unreachable,
      };
}

/// Term naming read from the scheme's own labels (FUTO's Harmattan/Rain,
/// not the generic First/Second) — abbreviated to 3 letters so "100L Har"
/// fits the chart's x-axis, never the generic "1st"/"2nd" shortLabel.
String _shortTermLabel(GradingScheme scheme, SemesterTerm term) {
  final word = scheme.termLabel(term).split(' ').first;
  return word.length <= 3 ? word : word.substring(0, 3);
}

class TrendCard extends StatelessWidget {
  final AcademicStanding standing;
  final GradingScheme scheme;
  final List<Semester> rawSemesters;
  final TargetProjection? goal;

  const TrendCard({
    super.key,
    required this.standing,
    required this.scheme,
    required this.rawSemesters,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final delta = standing.semesters.length >= 2 ? standing.recentTrend(window: 2) : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CGPA trend',
                style: TextStyle(
                  color: context.palette.bodyText,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (delta != null) _DeltaChip(delta: delta),
            ],
          ),
          const SizedBox(height: 16),
          standing.semesters.length < 2
              ? const TrendPlaceholder()
              : RepaintBoundary(
                  child: _TrendChartBody(
                    standing: standing,
                    scheme: scheme,
                    rawSemesters: rawSemesters,
                    goal: goal,
                  ),
                ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final double delta;

  const _DeltaChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    final color = delta > 0
        ? context.palette.success
        : delta < 0
            ? context.palette.amber
            : context.palette.secondaryText;
    final icon = delta > 0 ? Icons.arrow_upward : Icons.arrow_downward;
    final text = '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TrendChartBody extends StatefulWidget {
  final AcademicStanding standing;
  final GradingScheme scheme;
  final List<Semester> rawSemesters;
  final TargetProjection? goal;

  const _TrendChartBody({
    required this.standing,
    required this.scheme,
    required this.rawSemesters,
    required this.goal,
  });

  @override
  State<_TrendChartBody> createState() => _TrendChartBodyState();
}

class _TrendChartBodyState extends State<_TrendChartBody> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int _courseCountFor(SemesterComputation comp) {
    for (final s in widget.rawSemesters) {
      if (s.id == comp.semesterId) return s.results.length;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final standing = widget.standing;
    final scheme = widget.scheme;
    final trend = standing.cumulativeCgpaTrend;
    final maxPoint = scheme.maxPoint;
    final lastIndex = trend.length - 1;

    final realSpots = [for (var i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i])];
    final flatSpots = [for (var i = 0; i < trend.length; i++) FlSpot(i.toDouble(), 0)];
    final spots = _ready ? realSpots : flatSpots;

    // Hoisted out of `AnimatedBuilder` below -- these only depend on
    // `standing`/`scheme`/`goal`/`_ready`, never on the pulse dot's
    // animation value, so they used to get rebuilt (every `for` loop,
    // closure, and label resolver included) on every one of the pulse
    // controller's ticks, forever, for as long as this card was on
    // screen -- the most-visited screen in the app. Computed once per
    // actual data change instead.
    const gridData = FlGridData(show: false);
    final borderData = FlBorderData(
      show: true,
      border: const Border(bottom: BorderSide(color: Color(0xFFECECF1), width: 1)),
    );
    final rangeAnnotations = RangeAnnotations(
      horizontalRangeAnnotations: [
        for (final band in scheme.classifications)
          if (band.minCgpa < maxPoint)
            HorizontalRangeAnnotation(
              y1: band.minCgpa.clamp(0, maxPoint),
              y2: (band.maxCgpa > maxPoint ? maxPoint : band.maxCgpa).toDouble(),
              color: ClassificationPalette.colorForBandIndex(
                scheme.bandsDescending.indexWhere((b) => b.label == band.label),
              ).withValues(alpha: 0.04),
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
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ),
        if (widget.goal != null)
          HorizontalLine(
            y: widget.goal!.targetCgpa,
            color: widget.goal!.feasibility.color.withValues(alpha: 0.5),
            strokeWidth: 1.5,
            dashArray: const [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topLeft,
              labelResolver: (_) => 'Goal ${_fmt(widget.goal!.targetCgpa)}',
              style: TextStyle(
                fontSize: 11.5,
                color: widget.goal!.feasibility.color.withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
    final titlesData = FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= standing.semesters.length) return const SizedBox();
            final comp = standing.semesters[i];
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${comp.level}L ${_shortTermLabel(scheme, comp.term)}',
                style: TextStyle(color: context.palette.secondaryText, fontSize: 13),
              ),
            );
          },
        ),
      ),
    );
    final lineTouchData = LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => Colors.transparent,
        tooltipPadding: EdgeInsets.zero,
        tooltipMargin: 8,
        getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
          final i = spot.x.round();
          if (i < 0 || i >= standing.semesters.length) {
            return null;
          }
          final comp = standing.semesters[i];
          return LineTooltipItem(
            _fmt(spot.y),
            TextStyle(
              color: context.palette.bodyText,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(
                text: '\n${_fmt(comp.gpa)} GPA · ${comp.creditUnits}cr · '
                    '${_courseCountFor(comp)} courses',
                style: TextStyle(
                  color: context.palette.secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );

    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final accent = context.palette.primary;
          final accentLight = context.palette.primaryGradientStart;
          final barData = LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.28,
            barWidth: 3,
            gradient: LinearGradient(
              colors: [accentLight, accent],
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.0),
                ],
              ),
            ),
            dotData: FlDotData(
              getDotPainter: (spot, percent, bar, index) {
                if (index == lastIndex && _ready) {
                  return _PulseDotPainter(
                    pulse: _pulseController.value,
                    color: accent,
                  );
                }
                return FlDotCirclePainter(
                  radius: 5,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: accent,
                );
              },
            ),
          );

          return LineChart(
            LineChartData(
              minY: 0,
              maxY: maxPoint,
              gridData: gridData,
              borderData: borderData,
              rangeAnnotations: rangeAnnotations,
              extraLinesData: extraLinesData,
              titlesData: titlesData,
              lineBarsData: [barData],
              showingTooltipIndicators: _ready
                  ? [
                      for (var i = 0; i < spots.length; i++)
                        ShowingTooltipIndicators([LineBarSpot(barData, 0, spots[i])]),
                    ]
                  : [],
              lineTouchData: lineTouchData,
            ),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
          );
        },
      ),
    );
  }
}

class _PulseDotPainter extends FlDotPainter {
  final double pulse;
  final Color color;

  _PulseDotPainter({required this.pulse, required this.color});

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    final haloRadius = 14 * (1.0 + 0.15 * pulse);
    canvas.drawCircle(offsetInCanvas, haloRadius, Paint()..color = color.withValues(alpha: 0.20));
    canvas.drawCircle(offsetInCanvas, 7, Paint()..color = color);
  }

  @override
  Size getSize(FlSpot spot) => const Size(32, 32);

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) => t < 0.5 ? a : b;

  @override
  List<Object?> get props => [pulse, color];
}

/// Shown in place of the chart when there's exactly one semester — a
/// single point has no trend to draw, but it isn't an error state either.
class TrendPlaceholder extends StatelessWidget {
  const TrendPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart, size: 32, color: Color(0xFFD1D5DB)),
              SizedBox(height: 8),
              Text(
                'Add one more semester to see your trend',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.palette.secondaryText, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

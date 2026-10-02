/// A pseudo-3D bar view of GPA per semester, sitting alongside (not
/// replacing) `trend_chart.dart`'s line chart -- that one shows the running
/// CGPA trend, this one gives an at-a-glance, more visual read of each
/// semester's own GPA. Every bar height and colour still traces back to
/// [SemesterComputation]/[GradingScheme.classify] -- the "3D" is purely a
/// CustomPainter illustration technique (front/top/side faces per bar,
/// isometric-style), not a fabricated metric.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';

String _fmt(double v) => v.toStringAsFixed(2);

class Trend3DChart extends StatefulWidget {
  final AcademicStanding standing;
  final GradingScheme scheme;

  const Trend3DChart({super.key, required this.standing, required this.scheme});

  @override
  State<Trend3DChart> createState() => _Trend3DChartState();
}

class _Trend3DChartState extends State<Trend3DChart> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _grow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorFor(double gpa) {
    final band = widget.scheme.classify(gpa);
    if (band == null) return OnboardingLightPalette.secondaryText;
    final index = widget.scheme.bandsDescending.indexWhere((b) => b.label == band.label);
    return ClassificationPalette.colorForBandIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final semesters = widget.standing.semesters.where((s) => s.creditUnits > 0).toList();
    // A single block can't show a comparison -- but disappearing outright
    // (the old behaviour) read as "the chart is missing," not "there's
    // nothing to compare yet." `TrendCard`'s line chart has the same
    // one-semester gate and shows an explicit placeholder instead of
    // vanishing; this does the same for consistency.
    if (semesters.length < 2) return const _Trend3DPlaceholder();

    final shown = semesters.length > 6 ? semesters.sublist(semesters.length - 6) : semesters;
    final maxPoint = widget.scheme.maxPoint;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance View',
            style: TextStyle(
              color: OnboardingLightPalette.bodyText,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Each semester\'s GPA, block by block',
            style: TextStyle(color: OnboardingLightPalette.secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: _grow,
            builder: (context, _) => SizedBox(
              height: 160,
              child: CustomPaint(
                size: Size.infinite,
                painter: _Bars3DPainter(
                  semesters: shown,
                  maxPoint: maxPoint,
                  colorFor: _colorFor,
                  grow: _grow.value,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final s in shown)
                Expanded(
                  child: Text(
                    '${s.level}L·${s.term.shortLabel}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: OnboardingLightPalette.secondaryText, fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bars3DPainter extends CustomPainter {
  final List<SemesterComputation> semesters;
  final double maxPoint;
  final Color Function(double gpa) colorFor;
  final double grow;

  static const _depth = 9.0;
  static const _labelSpace = 22.0;

  _Bars3DPainter({
    required this.semesters,
    required this.maxPoint,
    required this.colorFor,
    required this.grow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - _labelSpace - _depth;
    final baseY = size.height - _labelSpace;
    final slot = size.width / semesters.length;
    final barWidth = (slot * 0.44).clamp(18.0, 40.0);

    for (var i = 0; i < semesters.length; i++) {
      final comp = semesters[i];
      final fraction = maxPoint <= 0 ? 0.0 : (comp.gpa / maxPoint).clamp(0.0, 1.0);
      final height = chartHeight * fraction * grow;
      if (height <= 0.5) continue;

      final centerX = slot * i + slot / 2;
      final left = centerX - barWidth / 2;
      final right = centerX + barWidth / 2;
      final top = baseY - height;

      final color = colorFor(comp.gpa);
      final front = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.95), color],
        ).createShader(Rect.fromLTRB(left, top, right, baseY));
      final topFace = Paint()..color = Color.lerp(color, Colors.white, 0.45)!;
      final sideFace = Paint()..color = Color.lerp(color, Colors.black, 0.20)!;

      // Right side face (darker) -- gives the block visual thickness.
      final side = Path()
        ..moveTo(right, top)
        ..lineTo(right + _depth, top - _depth)
        ..lineTo(right + _depth, baseY - _depth)
        ..lineTo(right, baseY)
        ..close();
      canvas.drawPath(side, sideFace);

      // Front face.
      final frontRect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, top, right, baseY),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(frontRect, front);

      // Top face (lighter) -- the parallelogram "cap" that sells the tilt.
      final topPath = Path()
        ..moveTo(left, top)
        ..lineTo(right, top)
        ..lineTo(right + _depth, top - _depth)
        ..lineTo(left + _depth, top - _depth)
        ..close();
      canvas.drawPath(topPath, topFace);

      // Value label above the block, fading in with growth.
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: _fmt(comp.gpa),
          style: TextStyle(
            color: OnboardingLightPalette.bodyText.withValues(alpha: grow),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      )..layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, top - _depth - textPainter.height - 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Bars3DPainter oldDelegate) =>
      oldDelegate.grow != grow || oldDelegate.semesters != semesters;
}

class _Trend3DPlaceholder extends StatelessWidget {
  const _Trend3DPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance View',
            style: TextStyle(color: OnboardingLightPalette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 16),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_in_ar_outlined, size: 32, color: Color(0xFFD1D5DB)),
                  SizedBox(height: 8),
                  Text(
                    'Add one more semester to see this view',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: OnboardingLightPalette.secondaryText, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

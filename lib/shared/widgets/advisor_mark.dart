/// The advisor's mark — a small custom-painted "face," not an asset, so it
/// scales cleanly from a 28dp FAB icon up to a 76dp greeting-card avatar.
///
/// [neutral] swaps the smile for a flat line — the tone gate the AI tab
/// applies whenever the critical-standing card is active, since cheerful
/// iconography above a card telling a student they're below the pass mark
/// reads as mockery. [simplified] drops the antennae and sparkles for
/// small/incidental uses (the FAB, the chat sheet header) where they'd just
/// be visual noise. Sparkles only ever render (and only ever animate) on
/// the full, non-simplified mark.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class AdvisorMark extends StatefulWidget {
  final double size;
  final bool simplified;
  final bool neutral;

  /// Head fill colour. Defaults to the current theme accent
  /// (`context.palette.primary`) when unset -- the FAB and a couple of
  /// on-colour placements pass an explicit override (e.g. white, to sit on
  /// its own accent-coloured circle) instead.
  final Color? color;

  const AdvisorMark({
    super.key,
    required this.size,
    this.simplified = false,
    this.neutral = false,
    this.color,
  });

  @override
  State<AdvisorMark> createState() => _AdvisorMarkState();
}

class _AdvisorMarkState extends State<AdvisorMark> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAnimate();
  }

  @override
  void didUpdateWidget(covariant AdvisorMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeAnimate();
  }

  void _maybeAnimate() {
    final shouldAnimate =
        !widget.simplified && !widget.neutral && !MediaQuery.disableAnimationsOf(context);
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = widget.color ?? palette.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _AdvisorMarkPainter(
          t: _controller.value,
          simplified: widget.simplified,
          neutral: widget.neutral,
          color: color,
          neutralFeatureColor: palette.primary,
          sparkleColor: palette.primaryGradientStart,
        ),
      ),
    );
  }
}

class _AdvisorMarkPainter extends CustomPainter {
  final double t;
  final bool simplified;
  final bool neutral;
  final Color color;

  /// Eye/smile colour when [color] is light enough that white features
  /// wouldn't show (e.g. the FAB's white head) — the current theme accent,
  /// not a fixed purple.
  final Color neutralFeatureColor;

  /// Sparkle colour — a lighter tint of the current accent.
  final Color sparkleColor;

  /// Reference artboard width the dp values in the task brief were
  /// specified against — the painter scales everything proportionally to
  /// whatever [Size] it's actually asked to fill.
  static const _referenceWidth = 60.0;

  const _AdvisorMarkPainter({
    required this.t,
    required this.simplified,
    required this.neutral,
    required this.color,
    required this.neutralFeatureColor,
    required this.sparkleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _referenceWidth;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);

    const headWidth = 44.0;
    const headHeight = 38.0;
    final headRect = Rect.fromCenter(center: Offset.zero, width: headWidth, height: headHeight);
    final headPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, const Radius.circular(14)),
      headPaint,
    );

    // Eyes/smile need to contrast with whatever `color` the head is
    // filled with — normally white-on-accent, but the FAB draws a white
    // head (to sit on its own accent-coloured background), which would
    // otherwise put white eyes on a white head. [neutralFeatureColor] is
    // only safe to use as that light-head fallback when it's ITSELF dark
    // enough to show -- for every accent this holds (it's `palette.primary`,
    // normally a saturated colour), but for the two light accents (White,
    // Light Blue) `color` defaults to `palette.primary` too, so
    // `neutralFeatureColor` collapses to the exact same light colour as
    // the head it's meant to contrast against. A guaranteed-dark final
    // fallback closes that gap without hardcoding a fixed accent.
    final lightHeadFeatureColor =
        neutralFeatureColor.computeLuminance() > 0.5 ? Colors.black87 : neutralFeatureColor;
    final featureColor =
        color.computeLuminance() > 0.5 ? lightHeadFeatureColor : Colors.white;

    final headTop = headRect.top;
    final eyeY = headTop + headHeight * 0.40;
    final eyePaint = Paint()..color = featureColor;
    canvas.drawCircle(Offset(-5.5, eyeY), 4.5, eyePaint);
    canvas.drawCircle(Offset(5.5, eyeY), 4.5, eyePaint);

    final mouthY = headTop + headHeight * 0.68;
    final mouthPaint = Paint()
      ..color = featureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    if (neutral) {
      canvas.drawLine(Offset(-7, mouthY), Offset(7, mouthY), mouthPaint);
    } else {
      final smileRect = Rect.fromCenter(center: Offset(0, mouthY - 4), width: 14, height: 14);
      // Sweeps downward across the bottom of the arc -- a gentle smile.
      canvas.drawArc(smileRect, math.pi * 0.15, math.pi * 0.7, false, mouthPaint);
    }

    if (!simplified) {
      final antennaPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (final side in [-1.0, 1.0]) {
        final baseX = side * headWidth / 2 * 0.6;
        final baseY = headTop;
        final angle = side * (math.pi / 180) * 25;
        final tip = Offset(baseX + math.sin(angle) * 7, baseY - math.cos(angle) * 7);
        canvas.drawLine(Offset(baseX, baseY), tip, antennaPaint);
        canvas.drawCircle(tip, 1.5, Paint()..color = color);
      }

      final sparklePaint = Paint()..color = sparkleColor;
      final sparkles = [
        (const Offset(headWidth / 2 + 4, -headHeight / 2 - 2), 8.0, 0.9, 0.0),
        (const Offset(headWidth / 2 + 12, -headHeight / 2 + 6), 5.0, 0.7, 1 / 3),
        (const Offset(headWidth / 2 + 6, -headHeight / 2 + 14), 4.0, 0.5, 2 / 3),
      ];
      for (final (center, starSize, baseAlpha, phase) in sparkles) {
        final pulse = 0.5 + 0.5 * math.sin(2 * math.pi * (t - phase));
        final alpha = (baseAlpha * (0.4 + 0.6 * pulse)).clamp(0.0, 1.0);
        _drawStar(canvas, center, starSize, sparklePaint..color = sparkleColor.withValues(alpha: alpha));
      }
    }

    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final r = size / 2;
    path.moveTo(center.dx, center.dy - r);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AdvisorMarkPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.simplified != simplified ||
      oldDelegate.neutral != neutral ||
      oldDelegate.color != color ||
      oldDelegate.neutralFeatureColor != neutralFeatureColor ||
      oldDelegate.sparkleColor != sparkleColor;
}

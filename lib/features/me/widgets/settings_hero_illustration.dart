/// The settings screen's hero mark -- a shield (data protection) with a
/// padlock, overlapped by a slowly-rotating gear (configuration). A
/// [CustomPainter], not an asset, matching the rest of this app's
/// illustration idiom (`BadgeShield`, `NotificationBellIllustration`).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class SettingsHeroIllustration extends StatefulWidget {
  const SettingsHeroIllustration({super.key});

  @override
  State<SettingsHeroIllustration> createState() => _SettingsHeroIllustrationState();
}

class _SettingsHeroIllustrationState extends State<SettingsHeroIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: const Size(110, 110),
        painter: _ShieldGearPainter(gearTurns: _controller.value),
      ),
    );
  }
}

class _ShieldGearPainter extends CustomPainter {
  final double gearTurns;

  const _ShieldGearPainter({required this.gearTurns});

  Path _shieldPath(Offset topLeft, double w, double shoulderW) {
    const cornerRadius = 6.0;
    const pointRadius = 5.0;
    final h = w * 72 / 62;
    final sideBottom = h * 0.55;
    return Path()
      ..moveTo(topLeft.dx + cornerRadius, topLeft.dy)
      ..lineTo(topLeft.dx + shoulderW - cornerRadius, topLeft.dy)
      ..quadraticBezierTo(
        topLeft.dx + shoulderW, topLeft.dy, topLeft.dx + shoulderW, topLeft.dy + cornerRadius)
      ..lineTo(topLeft.dx + shoulderW, topLeft.dy + sideBottom)
      ..cubicTo(
        topLeft.dx + shoulderW, topLeft.dy + sideBottom + (h - sideBottom) * 0.6,
        topLeft.dx + shoulderW / 2 + pointRadius, topLeft.dy + h - pointRadius * 1.4,
        topLeft.dx + shoulderW / 2, topLeft.dy + h,
      )
      ..cubicTo(
        topLeft.dx + shoulderW / 2 - pointRadius, topLeft.dy + h - pointRadius * 1.4,
        topLeft.dx, topLeft.dy + sideBottom + (h - sideBottom) * 0.6,
        topLeft.dx, topLeft.dy + sideBottom,
      )
      ..lineTo(topLeft.dx, topLeft.dy + cornerRadius)
      ..quadraticBezierTo(topLeft.dx, topLeft.dy, topLeft.dx + cornerRadius, topLeft.dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    const shieldWidth = 62.0;
    const shieldHeight = 72.0;
    final shieldTopLeft = Offset(size.width / 2 - shieldWidth / 2, size.height / 2 - shieldHeight / 2 - 4);
    final path = _shieldPath(shieldTopLeft, shieldWidth, shieldWidth);
    final bounds = Rect.fromLTWH(shieldTopLeft.dx, shieldTopLeft.dy, shieldWidth, shieldHeight);
    final center = bounds.center;

    // Drop shadow, painted first so the body sits above it.
    canvas.save();
    canvas.translate(0, 5);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0F0F14).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.restore();

    // Body: diagonal gradient fill.
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C6FE8), Color(0xFF4A3BC4)],
        ).createShader(bounds),
    );

    // Inner bevel: an inset copy of the same contour, stroked.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(0.92);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFA5B4FC).withValues(alpha: 0.35),
    );
    canvas.restore();

    // Highlight band along the upper-left edge.
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFC4B5FD).withValues(alpha: 0.40),
            const Color(0xFFC4B5FD).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.30],
        ).createShader(bounds),
    );
    canvas.restore();

    _paintPadlock(canvas, Offset(center.dx, shieldTopLeft.dy + shieldHeight * 0.45));

    canvas.save();
    canvas.translate(bounds.right - 6, bounds.bottom - 22);
    canvas.rotate(gearTurns * 2 * math.pi);
    canvas.translate(-(bounds.right - 6), -(bounds.bottom - 22));
    _paintGear(canvas, Offset(bounds.right - 6, bounds.bottom - 22));
    canvas.restore();
  }

  void _paintPadlock(Canvas canvas, Offset center) {
    final bodyRect = Rect.fromCenter(center: center + const Offset(0, 4), width: 26, height: 22);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(5));

    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, bodyRect.top), width: 16, height: 16),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white,
    );

    canvas.drawRRect(bodyRRect, Paint()..color = Colors.white);

    final keyholeCenter = bodyRect.center;
    canvas.drawCircle(keyholeCenter, 2.5, Paint()..color = const Color(0xFF5B4BD4));
    final slot = Path()
      ..moveTo(keyholeCenter.dx - 1.5, keyholeCenter.dy + 1)
      ..lineTo(keyholeCenter.dx + 1.5, keyholeCenter.dy + 1)
      ..lineTo(keyholeCenter.dx + 1, keyholeCenter.dy + 6)
      ..lineTo(keyholeCenter.dx - 1, keyholeCenter.dy + 6)
      ..close();
    canvas.drawPath(slot, Paint()..color = const Color(0xFF5B4BD4));
  }

  void _paintGear(Canvas canvas, Offset center) {
    const outerRadius = 20.0;
    const innerRadius = 13.0;
    const teeth = 8;
    const toothOuterSweep = 22 * math.pi / 180;
    const toothInnerSweep = 16 * math.pi / 180;
    const step = 2 * math.pi / teeth;

    final path = Path();
    for (var i = 0; i < teeth; i++) {
      final mid = i * step;
      final outerStart = mid - toothOuterSweep / 2;
      final outerEnd = mid + toothOuterSweep / 2;
      final innerStart = mid + step / 2 - toothInnerSweep / 2;
      final innerEnd = mid + step / 2 + toothInnerSweep / 2;

      final p1 = center + Offset(math.cos(outerStart), math.sin(outerStart)) * outerRadius;
      final p2 = center + Offset(math.cos(outerEnd), math.sin(outerEnd)) * outerRadius;
      final p3 = center + Offset(math.cos(innerStart), math.sin(innerStart)) * innerRadius;
      final p4 = center + Offset(math.cos(innerEnd), math.sin(innerEnd)) * innerRadius;

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p4.dx, p4.dy);
      path.lineTo(p3.dx, p3.dy);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF7C6FE8),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF5B4BD4),
    );
    // Punches the centre hole -- approximates "reveals the scaffold colour"
    // since this painter has no knowledge of what's actually behind the
    // hero card at paint time.
    canvas.drawCircle(center, 8, Paint()..color = const Color(0xFFF1EFFE));
  }

  @override
  bool shouldRepaint(covariant _ShieldGearPainter oldDelegate) => oldDelegate.gearTurns != gearTurns;
}

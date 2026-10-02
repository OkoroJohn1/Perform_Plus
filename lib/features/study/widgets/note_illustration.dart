/// The Study hero banner's books-and-clock illustration — a
/// [CustomPainter], not an asset, to keep the bundle small (it's geometric
/// enough to draw). The clock's minute hand is the one live detail: it
/// turns one full rotation every 60 seconds, a slow readable clock rather
/// than a decorative loop, and is suppressed under reduced motion.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class NoteIllustration extends StatefulWidget {
  final double opacity;

  const NoteIllustration({super.key, this.opacity = 1.0});

  @override
  State<NoteIllustration> createState() => _NoteIllustrationState();
}

class _NoteIllustrationState extends State<NoteIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 60));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAnimate();
  }

  void _maybeAnimate() {
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
    return Opacity(
      opacity: widget.opacity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: const Size(130, 120),
          painter: _NoteIllustrationPainter(minuteTurn: _controller.value),
        ),
      ),
    );
  }
}

class _NoteIllustrationPainter extends CustomPainter {
  final double minuteTurn;

  const _NoteIllustrationPainter({required this.minuteTurn});

  static double _rad(double deg) => deg * math.pi / 180;

  RRect _book(Offset center, double width, double height, double skewDeg) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    return RRect.fromRectAndRadius(rect, const Radius.circular(2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final stackCenter = Offset(size.width * 0.42, size.height * 0.70);

    // Drop shadow beneath the stack.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: stackCenter + const Offset(0, 14), width: 90, height: 14),
        const Radius.circular(8),
      ),
      Paint()
        ..color = const Color(0xFF0F0F14).withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    _drawBook(canvas, stackCenter + const Offset(0, 8), 96, 18,
        spine: const Color(0xFF4A3BC4), top: const Color(0xFF6D5CE0));
    _drawBook(canvas, stackCenter + const Offset(4, -8), 88, 17,
        spine: const Color(0xFF7C6FE8), top: const Color(0xFF9A8FF0));
    _drawBook(canvas, stackCenter + const Offset(-2, -23), 80, 16,
        spine: const Color(0xFF3B82F6), top: const Color(0xFF60A5FA));

    _drawPlant(canvas, stackCenter + const Offset(20, -40));
    _drawClock(canvas, stackCenter + const Offset(-6, 6));
  }

  void _drawBook(Canvas canvas, Offset center, double width, double height,
      {required Color spine, required Color top}) {
    final rrect = _book(center, width, height, 12);
    canvas.drawRRect(rrect, Paint()..color = spine);

    final topFaceRect = Rect.fromLTWH(
      rrect.left,
      rrect.top - height * 0.28,
      width,
      height * 0.4,
    );
    final topPath = Path()
      ..moveTo(topFaceRect.left + 6, topFaceRect.bottom)
      ..lineTo(topFaceRect.right - 6, topFaceRect.bottom)
      ..lineTo(topFaceRect.right, topFaceRect.top)
      ..lineTo(topFaceRect.left, topFaceRect.top)
      ..close();
    canvas.drawPath(topPath, Paint()..color = top);

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = spine.withValues(alpha: 0.6),
    );

    final pageX = rrect.right - 3;
    final pagePaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = rrect.top + rrect.height * (0.25 + i * 0.25);
      canvas.drawLine(Offset(pageX, y), Offset(pageX - 6, y), pagePaint);
    }
  }

  void _drawPlant(Canvas canvas, Offset base) {
    final potPath = Path()
      ..moveTo(base.dx - 13, base.dy)
      ..lineTo(base.dx + 13, base.dy)
      ..lineTo(base.dx + 10, base.dy + 22)
      ..lineTo(base.dx - 10, base.dy + 22)
      ..close();
    canvas.drawPath(potPath, Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawPath(
      potPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFCBD5E1),
    );

    const angles = [-40.0, -18.0, 0.0, 20.0, 42.0];
    for (var i = 0; i < angles.length; i++) {
      final angle = _rad(angles[i]);
      final leafBase = base;
      final tip = leafBase + Offset(math.sin(angle) * 22, -math.cos(angle) * 22);
      final perpendicular = Offset(math.cos(angle), math.sin(angle)) * 4.5;

      final path = Path()
        ..moveTo(leafBase.dx, leafBase.dy)
        ..quadraticBezierTo(
          (leafBase.dx + tip.dx) / 2 + perpendicular.dx,
          (leafBase.dy + tip.dy) / 2 + perpendicular.dy,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          (leafBase.dx + tip.dx) / 2 - perpendicular.dx,
          (leafBase.dy + tip.dy) / 2 - perpendicular.dy,
          leafBase.dx,
          leafBase.dy,
        )
        ..close();

      final color = i.isEven ? const Color(0xFF16A34A) : const Color(0xFF22C55E);
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawLine(
        leafBase,
        tip,
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..strokeWidth = 1,
      );
    }
  }

  void _drawClock(Canvas canvas, Offset center) {
    const faceRadius = 21.0;
    canvas.drawCircle(center, faceRadius, Paint()..color = const Color(0xFFFEF3C7));
    canvas.drawCircle(
      center,
      faceRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFF59E0B),
    );

    for (final side in [-1.0, 1.0]) {
      final angle = _rad(side * 38) - math.pi / 2;
      final bellCenter = center + Offset(math.cos(angle), math.sin(angle)) * faceRadius;
      canvas.drawCircle(bellCenter, 7, Paint()..color = const Color(0xFFF59E0B));
      canvas.drawArc(
        Rect.fromCircle(center: bellCenter, radius: 5),
        _rad(200),
        _rad(90),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFBBF24),
      );
    }

    for (final side in [-1.0, 1.0]) {
      final angle = _rad(side * 25) + math.pi / 2;
      final legStart = center + Offset(math.cos(angle), math.sin(angle)) * faceRadius;
      final legEnd = center + Offset(math.cos(angle), math.sin(angle)) * (faceRadius + 8);
      canvas.drawLine(
        legStart,
        legEnd,
        Paint()
          ..color = const Color(0xFFF59E0B)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    final tickPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.5)
      ..strokeWidth = 2;
    for (var i = 0; i < 12; i++) {
      final angle = _rad(i * 30.0) - math.pi / 2;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + dir * (faceRadius - 5),
        center + dir * (faceRadius - 3),
        tickPaint,
      );
    }

    final handPaint = Paint()
      ..color = const Color(0xFF0F0F14)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final hourAngle = _rad(-60) - math.pi / 2;
    canvas.drawLine(
      center,
      center + Offset(math.cos(hourAngle), math.sin(hourAngle)) * 12,
      handPaint,
    );
    final minuteAngle = 2 * math.pi * minuteTurn - math.pi / 2;
    canvas.drawLine(
      center,
      center + Offset(math.cos(minuteAngle), math.sin(minuteAngle)) * 16,
      handPaint,
    );
    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFF0F0F14));
  }

  @override
  bool shouldRepaint(covariant _NoteIllustrationPainter oldDelegate) =>
      oldDelegate.minuteTurn != minuteTurn;
}

/// The notification panel's hero-banner bell — a [CustomPainter], not an
/// asset. Rocks gently on a periodic chime rather than constant motion,
/// and shows the actual unread count on its badge (never a decorative
/// placeholder number).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class NotificationBellIllustration extends StatefulWidget {
  final int unreadCount;

  const NotificationBellIllustration({super.key, required this.unreadCount});

  @override
  State<NotificationBellIllustration> createState() => _NotificationBellIllustrationState();
}

class _NotificationBellIllustrationState extends State<NotificationBellIllustration>
    with SingleTickerProviderStateMixin {
  // 1600ms rock + 3000ms pause per the brief.
  static const _cycle = Duration(milliseconds: 4600);
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycle);
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: const Size(120, 120),
        painter: _BellPainter(t: _controller.value, unreadCount: widget.unreadCount),
      ),
    );
  }
}

class _BellPainter extends CustomPainter {
  final double t;
  final int unreadCount;

  const _BellPainter({required this.t, required this.unreadCount});

  /// 1600ms of an easeInOut rock, then a 3000ms pause, over the full
  /// 4600ms cycle — [t] is that cycle's 0..1 progress.
  double get _rockAngleDegrees {
    const rockFraction = 1600 / 4600;
    if (t > rockFraction) return 0;
    final phase = t / rockFraction; // 0..1 across the rock itself
    final eased = Curves.easeInOut.transform((math.sin(phase * math.pi * 2) + 1) / 2);
    return (eased - 0.5) * 12; // +/-6 degrees
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 6);
    final pivot = Offset(center.dx, center.dy - 34);

    _paintDiamonds(canvas, center, t);

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(_rockAngleDegrees * math.pi / 180);
    canvas.translate(-pivot.dx, -pivot.dy);

    _paintCrownLoop(canvas, pivot);
    final bodyPath = _bellBodyPath(center);
    _paintBody(canvas, bodyPath, center);
    _paintClapper(canvas, center);

    canvas.restore();

    if (unreadCount > 0) _paintBadge(canvas, Offset(center.dx + 26, center.dy - 40));
  }

  Path _bellBodyPath(Offset center) {
    final top = center - const Offset(0, 34);
    final lipY = center.dy + 20;
    return Path()
      ..moveTo(top.dx, top.dy)
      ..cubicTo(
        top.dx - 8, top.dy + 4,
        center.dx - 30, center.dy - 20,
        center.dx - 31, lipY - 9,
      )
      ..lineTo(center.dx - 31, lipY - 6)
      ..arcToPoint(Offset(center.dx - 28, lipY), radius: const Radius.circular(3))
      ..lineTo(center.dx + 28, lipY)
      ..arcToPoint(Offset(center.dx + 31, lipY - 6), radius: const Radius.circular(3))
      ..lineTo(center.dx + 31, lipY - 9)
      ..cubicTo(
        center.dx + 30, center.dy - 20,
        top.dx + 8, top.dy + 4,
        top.dx, top.dy,
      )
      ..close();
  }

  void _paintBody(Canvas canvas, Path path, Offset center) {
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7C6FE8), Color(0xFF5B4BD4)],
        ).createShader(bounds),
    );

    canvas.save();
    canvas.clipPath(path);
    canvas.drawCircle(
      center + const Offset(-18, 6),
      26,
      Paint()
        ..color = const Color(0xFF4A3BC4).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      center + const Offset(16, -18),
      20,
      Paint()
        ..color = const Color(0xFFA5B4FC).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.restore();
  }

  void _paintClapper(Canvas canvas, Offset center) {
    final clapperCenter = Offset(center.dx, center.dy + 26);
    canvas.drawCircle(clapperCenter, 6.5, Paint()..color = const Color(0xFF4A3BC4));
    canvas.drawArc(
      Rect.fromCircle(center: clapperCenter, radius: 6.5),
      math.pi * 1.1,
      math.pi * 0.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF7C6FE8),
    );
  }

  void _paintCrownLoop(Canvas canvas, Offset pivot) {
    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: 7),
      math.pi * 1.05,
      math.pi * 1.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF5B4BD4),
    );
  }

  void _paintBadge(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 14, Paint()..color = const Color(0xFFF7F7FB));
    canvas.drawCircle(center, 14, Paint()..color = const Color(0xFFEF4444));

    final label = unreadCount > 9 ? '9+' : '$unreadCount';
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
      ),
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  void _paintDiamonds(Canvas canvas, Offset bellCenter, double t) {
    final drift = math.sin(t * 2 * math.pi) * 3;
    final specs = [
      (bellCenter + Offset(-38, -36 + drift), 9.0, const Color(0xFFA5B4FC), 0.70),
      (bellCenter + Offset(-42, -6 - drift), 7.0, const Color(0xFFFCA5A5), 0.65),
      (bellCenter + Offset(34, 30 + drift), 6.0, const Color(0xFFA5B4FC), 0.55),
    ];
    for (final (pos, size, color, alpha) in specs) {
      final rect = Rect.fromCenter(center: pos, width: size, height: size);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(1));
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(math.pi / 4);
      canvas.translate(-pos.dx, -pos.dy);
      canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: alpha));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BellPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.unreadCount != unreadCount;
}

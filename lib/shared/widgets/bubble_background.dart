/// Shining white bubbles drifting upward over a dark backdrop — used behind
/// the splash screen. Each bubble is a soft white radial glow (not a flat
/// circle) rising with a gentle side-to-side sway, looping on its own timer
/// so the motion never quite repeats. Sizes/speeds/opacities vary per
/// bubble for a sparkle read rather than a mechanical pattern.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class BubbleBackground extends StatefulWidget {
  const BubbleBackground({super.key});

  @override
  State<BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<BubbleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  static const _specs = [
    _BubbleSpec(size: 26, startX: 0.12, speed: 1.0, phase: 0.0, sway: 0.05, maxAlpha: 0.85),
    _BubbleSpec(size: 14, startX: 0.28, speed: 1.6, phase: 0.15, sway: 0.08, maxAlpha: 0.6),
    _BubbleSpec(size: 40, startX: 0.45, speed: 0.7, phase: 0.4, sway: 0.04, maxAlpha: 0.5),
    _BubbleSpec(size: 10, startX: 0.6, speed: 1.9, phase: 0.6, sway: 0.1, maxAlpha: 0.7),
    _BubbleSpec(size: 22, startX: 0.7, speed: 1.1, phase: 0.05, sway: 0.06, maxAlpha: 0.6),
    _BubbleSpec(size: 32, startX: 0.85, speed: 0.85, phase: 0.75, sway: 0.05, maxAlpha: 0.45),
    _BubbleSpec(size: 16, startX: 0.2, speed: 1.4, phase: 0.5, sway: 0.07, maxAlpha: 0.65),
    _BubbleSpec(size: 12, startX: 0.92, speed: 1.7, phase: 0.3, sway: 0.09, maxAlpha: 0.55),
    _BubbleSpec(size: 36, startX: 0.05, speed: 0.6, phase: 0.9, sway: 0.03, maxAlpha: 0.4),
    _BubbleSpec(size: 18, startX: 0.52, speed: 1.3, phase: 0.2, sway: 0.06, maxAlpha: 0.6),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _BubblesPainter(t: _controller.value, specs: _specs),
        );
      },
    );
  }
}

class _BubbleSpec {
  final double size;
  final double startX;
  final double speed;
  final double phase;
  final double sway;
  final double maxAlpha;

  const _BubbleSpec({
    required this.size,
    required this.startX,
    required this.speed,
    required this.phase,
    required this.sway,
    required this.maxAlpha,
  });
}

class _BubblesPainter extends CustomPainter {
  final double t;
  final List<_BubbleSpec> specs;

  _BubblesPainter({required this.t, required this.specs});

  @override
  void paint(Canvas canvas, Size size) {
    for (final spec in specs) {
      // Loops from bottom (1.2, just off-screen) to top (-0.2, just off-screen).
      final progress = (t * spec.speed + spec.phase) % 1.0;
      final y = (1.2 - progress * 1.4) * size.height;
      final x = (spec.startX + spec.sway * math.sin(progress * 4 * math.pi)) * size.width;

      // Fades in near the bottom, fades out near the top.
      final fade = math.sin(progress * math.pi).clamp(0.0, 1.0);
      final alpha = spec.maxAlpha * fade;

      final center = Offset(x, y);
      final radius = spec.size / 2;

      final glow = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: alpha),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 2));
      canvas.drawCircle(center, radius * 2, glow);

      final core = Paint()..color = Colors.white.withValues(alpha: alpha * 0.9);
      canvas.drawCircle(center, radius * 0.35, core);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => oldDelegate.t != t;
}

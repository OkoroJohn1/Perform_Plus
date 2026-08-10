/// Slow-drifting aurora glow, used behind the splash screen's dark
/// background. Three soft radial blobs (cyan, blue, violet) ease between
/// anchor points on independent loops so the motion never quite repeats.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

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
        final t = _controller.value * 2 * math.pi;
        return Stack(
          children: [
            _Blob(
              color: const Color(0xFF35D6E8),
              alignX: 0.35 + 0.3 * math.sin(t * 0.6),
              alignY: -0.9 + 0.3 * math.sin(t * 0.7),
              size: 340,
            ),
            _Blob(
              color: const Color(0xFF5B4BD4),
              alignX: -0.7 + 0.4 * math.sin(t * 0.5 + 1.5),
              alignY: 0.1 + 0.3 * math.sin(t * 0.9 + 2),
              size: 380,
            ),
            _Blob(
              color: const Color(0xFF8B7CF6),
              alignX: 0.3 * math.sin(t * 0.6 + 3),
              alignY: 0.85 + 0.2 * math.sin(t * 0.8),
              size: 320,
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double alignX;
  final double alignY;
  final double size;

  const _Blob({
    required this.color,
    required this.alignX,
    required this.alignY,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(alignX.clamp(-1.2, 1.2), alignY.clamp(-1.2, 1.2)),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

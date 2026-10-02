/// The flowing ribbon-line background behind the splash screen's logo
/// cluster. Self-contained: owns its own drift ticker (capped ~30fps, frame
/// skipping) and adapts its own render cost — drops particle trails, then
/// line count — if a frame gets expensive, per the itel P673L perf target.
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_theme.dart';

class _WaveSpec {
  /// Fraction of the field's height where the line enters at x = 0.
  final double entryFrac;

  /// Fraction of the field's height where the line exits at x = width.
  final double exitFrac;

  /// Per-line vertical fan offset, in logical pixels.
  final double offset;

  final double strokeWidth;
  final double opacity;
  final bool hasParticles;

  /// Horizontal drift speed for this line's internal control points, in
  /// logical pixels per second.
  final double driftSpeed;

  const _WaveSpec({
    required this.entryFrac,
    required this.exitFrac,
    required this.offset,
    required this.strokeWidth,
    required this.opacity,
    required this.hasParticles,
    required this.driftSpeed,
  });
}

/// Ordered by descending importance, not fan position — dropping to the
/// first N under perf pressure keeps the brightest, most central lines.
/// The two highest-opacity lines (`offset` closest to 0) read as "the
/// middle of the fan" once sorted by `offset`: -44, -32, -18, -6, 8, 24,
/// 36, 44 — consecutive gaps of 12–16dp, comfortably inside the 8–22dp
/// range that keeps the lines fanned rather than overlapping.
const List<_WaveSpec> _waveSpecs = [
  _WaveSpec(entryFrac: 0.70, exitFrac: 0.30, offset: 8, strokeWidth: 2.2, opacity: 0.90, hasParticles: true, driftSpeed: 0.78),
  _WaveSpec(entryFrac: 0.66, exitFrac: 0.26, offset: -6, strokeWidth: 2.0, opacity: 0.85, hasParticles: true, driftSpeed: 0.71),
  _WaveSpec(entryFrac: 0.60, exitFrac: 0.16, offset: 24, strokeWidth: 1.7, opacity: 0.70, hasParticles: true, driftSpeed: 0.85),
  _WaveSpec(entryFrac: 0.62, exitFrac: 0.22, offset: -18, strokeWidth: 1.6, opacity: 0.60, hasParticles: true, driftSpeed: 0.63),
  _WaveSpec(entryFrac: 0.56, exitFrac: 0.20, offset: 36, strokeWidth: 1.3, opacity: 0.50, hasParticles: false, driftSpeed: 0.90),
  _WaveSpec(entryFrac: 0.74, exitFrac: 0.34, offset: -32, strokeWidth: 1.2, opacity: 0.45, hasParticles: false, driftSpeed: 0.55),
  _WaveSpec(entryFrac: 0.58, exitFrac: 0.18, offset: 44, strokeWidth: 1.1, opacity: 0.40, hasParticles: false, driftSpeed: 0.42),
  _WaveSpec(entryFrac: 0.68, exitFrac: 0.32, offset: -44, strokeWidth: 1.0, opacity: 0.35, hasParticles: false, driftSpeed: 0.48),
];

const List<double> _gradientStops = [0.0, 0.35, 0.62, 0.85, 1.0];
const List<Color> _gradientColors = [
  SplashPalette.waveDeepBlue,
  SplashPalette.waveBlue,
  SplashPalette.wavePurple,
  SplashPalette.waveViolet,
  SplashPalette.waveMagenta,
];

Color _gradientColorAt(double t, double opacity) {
  final clamped = t.clamp(0.0, 1.0);
  for (var i = 0; i < _gradientStops.length - 1; i++) {
    if (clamped <= _gradientStops[i + 1]) {
      final localT = (clamped - _gradientStops[i]) /
          (_gradientStops[i + 1] - _gradientStops[i]);
      return Color.lerp(_gradientColors[i], _gradientColors[i + 1], localT)!
          .withValues(alpha: opacity);
    }
  }
  return _gradientColors.last.withValues(alpha: opacity);
}

Shader _lineShader(double fieldWidth, double fieldHeight, double opacity) {
  return LinearGradient(
    stops: _gradientStops,
    colors: [for (final c in _gradientColors) c.withValues(alpha: opacity)],
  ).createShader(Rect.fromLTWH(0, 0, fieldWidth, fieldHeight));
}

class WaveField extends StatefulWidget {
  /// When true (accessibility: reduce motion), renders one static frame —
  /// no drift ticker.
  final bool reduceMotion;

  const WaveField({super.key, this.reduceMotion = false});

  @override
  State<WaveField> createState() => _WaveFieldState();
}

class _WaveFieldState extends State<WaveField> with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  double _driftSeconds = 0;
  Duration _lastPaint = Duration.zero;

  // Adaptive render quality — mutated directly by the painter's own cost
  // measurement (not via setState; the ticker already drives repaints), so
  // a slow frame simplifies every frame after it, not just the next one.
  bool _particlesEnabled = true;
  int _lineCount = _waveSpecs.length;

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _ticker = createTicker(_onTick)..start();
    }
  }

  void _onTick(Duration elapsed) {
    // Cap the drift ticker at ~30fps by skipping frames that land inside
    // the same 33ms window — the wave layer is the only thing this ticker
    // repaints (see RepaintBoundary below), so this doesn't touch the
    // logo/text frame rate at all.
    if (elapsed - _lastPaint < const Duration(milliseconds: 33)) return;
    _lastPaint = elapsed;
    setState(() => _driftSeconds = elapsed.inMicroseconds / 1e6);
  }

  void _onPaintCost(Duration cost) {
    if (cost.inMicroseconds / 1000.0 <= 8.0) return;
    if (_particlesEnabled) {
      _particlesEnabled = false;
    } else if (_lineCount > 5) {
      _lineCount = 5;
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _WaveFieldPainter(
          driftSeconds: _driftSeconds,
          particlesEnabled: _particlesEnabled,
          lineCount: _lineCount,
          onPaintCost: _onPaintCost,
        ),
      ),
    );
  }
}

class _WaveFieldPainter extends CustomPainter {
  final double driftSeconds;
  final bool particlesEnabled;
  final int lineCount;
  final ValueChanged<Duration> onPaintCost;

  _WaveFieldPainter({
    required this.driftSeconds,
    required this.particlesEnabled,
    required this.lineCount,
    required this.onPaintCost,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stopwatch = Stopwatch()..start();
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final spec in _waveSpecs.take(lineCount)) {
      _paintLine(canvas, size, spec);
    }
    canvas.restore();
    stopwatch.stop();
    onPaintCost(stopwatch.elapsed);
  }

  Path _buildPath(Size field, _WaveSpec spec) {
    final w = field.width;
    final h = field.height;
    final entryY = spec.entryFrac * h + spec.offset;
    final exitY = spec.exitFrac * h + spec.offset;
    final drift = driftSeconds * spec.driftSpeed;

    final troughX = (0.22 * w + drift).clamp(0.08 * w, 0.38 * w);
    final troughY = (entryY + 0.14 * h).clamp(0.0, h);
    final crestX = (0.62 * w + drift).clamp(0.42 * w, 0.92 * w);
    final crestY = (exitY - 0.12 * h).clamp(0.0, h);

    return Path()
      ..moveTo(0, entryY)
      ..cubicTo(
        troughX * 0.45, entryY,
        troughX * 0.8, troughY,
        troughX, troughY,
      )
      ..cubicTo(
        lerpDouble(troughX, crestX, 0.4)!, troughY,
        lerpDouble(troughX, crestX, 0.75)!, crestY,
        crestX, crestY,
      )
      ..cubicTo(
        lerpDouble(crestX, w, 0.4)!, crestY,
        lerpDouble(crestX, w, 0.75)!, exitY,
        w, exitY,
      );
  }

  void _paintLine(Canvas canvas, Size field, _WaveSpec spec) {
    final path = _buildPath(field, spec);

    canvas.drawPath(
      path,
      Paint()
        ..shader = _lineShader(field.width, field.height, spec.opacity * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = spec.strokeWidth * 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = _lineShader(field.width, field.height, spec.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = spec.strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (particlesEnabled && spec.hasParticles) {
      _paintParticles(canvas, path, field.width, spec);
    }
  }

  void _paintParticles(Canvas canvas, Path path, double fieldWidth, _WaveSpec spec) {
    // Re-seeded identically every paint call so particles drift smoothly
    // with the path instead of re-randomising (flickering) each frame.
    final rng = math.Random(spec.hashCode);
    for (final metric in path.computeMetrics()) {
      var distance = 4.0;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          final t = (tangent.position.dx / fieldWidth).clamp(0.0, 1.0);
          final radius = 0.8 + 1.6 * rng.nextDouble();
          final opacity = (0.3 + 0.55 * rng.nextDouble()) * spec.opacity;
          canvas.drawCircle(
            tangent.position,
            radius,
            Paint()..color = _gradientColorAt(t, opacity.clamp(0.0, 1.0)),
          );
        }
        distance += 6.0 + 12.0 * rng.nextDouble();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveFieldPainter oldDelegate) =>
      oldDelegate.driftSeconds != driftSeconds ||
      oldDelegate.particlesEnabled != particlesEnabled ||
      oldDelegate.lineCount != lineCount;
}

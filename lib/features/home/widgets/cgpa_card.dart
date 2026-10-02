/// The dashboard's hero card — current CGPA plus goal progress.
///
/// The progress ring never plots a raw `currentCgpa / targetCgpa` ratio —
/// that treats every CGPA point as equally hard to earn, which is false.
/// Instead it measures distance travelled between the classification floor
/// immediately below the target and the target itself, so a student who is
/// already deep into the target's own band sees a ring close to full,
/// rather than a ring that can never fill because a 5.0 scale makes the
/// raw ratio structurally conservative. See [_goalRingProgress].
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/performance_flag.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/engine/projection_solver.dart';
import '../../../domain/models/grading_scheme.dart';

String _fmt(double v) => v.toStringAsFixed(2);

/// Feasibility -> ring presentation. These are the pale, on-gradient
/// variants (see [DashboardPalette] doc) — distinct from [FeasibilityPalette],
/// which is tuned for text on a white card.
extension _RingPresentation on Feasibility {
  Color get ringColor => switch (this) {
        Feasibility.secured || Feasibility.comfortable => DashboardPalette.ringSecured,
        Feasibility.withinReach => DashboardPalette.ringWithinReach,
        Feasibility.demanding => DashboardPalette.ringDemanding,
        Feasibility.extremelyDemanding => DashboardPalette.ringExtremelyDemanding,
        Feasibility.unreachable => Colors.white,
      };

  double get ringAlpha => this == Feasibility.unreachable ? 0.45 : 1.0;

  String get ringLabel => switch (this) {
        Feasibility.secured => 'Secured',
        Feasibility.comfortable => 'Comfortable',
        Feasibility.withinReach => 'Within reach',
        Feasibility.demanding => 'Demanding',
        Feasibility.extremelyDemanding => 'Very demanding',
        Feasibility.unreachable => 'Out of reach',
      };
}

/// The floor a target is measured against: the highest classification
/// minimum strictly below [targetCgpa], or zero if the target is already
/// the lowest defined band. Public so it can be unit-tested directly
/// against the worked example in the task brief.
double goalRingFloor(GradingScheme scheme, double targetCgpa) {
  final below = scheme.classifications
      .where((b) => b.minCgpa < targetCgpa)
      .map((b) => b.minCgpa);
  return below.isEmpty ? 0.0 : below.reduce((a, b) => a > b ? a : b);
}

/// Honest goal-ring progress — see this file's doc comment.
double goalRingProgress(GradingScheme scheme, TargetProjection goal) {
  final floor = goalRingFloor(scheme, goal.targetCgpa);
  final span = goal.targetCgpa - floor;
  if (span <= 0) return 1.0;
  return ((goal.currentCgpa - floor) / span).clamp(0.0, 1.0);
}

class CgpaCard extends StatelessWidget {
  final AcademicStanding standing;
  final GradingScheme scheme;
  final TargetProjection? goal;
  final ClassificationBand? goalBand;
  final VoidCallback onSetGoal;

  const CgpaCard({
    super.key,
    required this.standing,
    required this.scheme,
    required this.goal,
    required this.goalBand,
    required this.onSetGoal,
  });

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProjectionDetailSheet(
        standing: standing,
        scheme: scheme,
        goal: goal,
        goalBand: goalBand,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final band = standing.classification;
    final goal = this.goal;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.palette.primaryGradientStart, context.palette.primaryGradientEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: context.palette.primary.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Current CGPA',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      standing.hasData ? _fmt(standing.cgpa) : '—',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.5,
                      ),
                    ),
                    if (standing.hasData && standing.cgpa < lowPerformanceThreshold) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: lowPerformanceColor.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Below 3.50',
                              style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      band?.shortLabel ?? 'Not yet classified',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.white.withValues(alpha: 0.22),
              ),
              Expanded(
                flex: 4,
                child: goal == null
                    ? Center(child: _NoGoalPill(onTap: onSetGoal))
                    : _GoalColumn(scheme: scheme, goal: goal, band: goalBand),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoGoalPill extends StatelessWidget {
  final VoidCallback onTap;

  const _NoGoalPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.40), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Set a goal',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalColumn extends StatelessWidget {
  final GradingScheme scheme;
  final TargetProjection goal;
  final ClassificationBand? band;

  const _GoalColumn({required this.scheme, required this.goal, required this.band});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Goal: ${band?.shortLabel ?? goal.targetLabel ?? ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          goal.feasibility.ringLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: goal.feasibility.ringColor.withValues(alpha: goal.feasibility.ringAlpha),
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _GoalRing(scheme: scheme, goal: goal),
      ],
    );
  }
}

class _GoalRing extends StatefulWidget {
  final GradingScheme scheme;
  final TargetProjection goal;

  const _GoalRing({required this.scheme, required this.goal});

  @override
  State<_GoalRing> createState() => _GoalRingState();
}

class _GoalRingState extends State<_GoalRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _value;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    final target = goalRingProgress(widget.scheme, widget.goal);
    _value = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.goal.feasibility.ringColor.withValues(alpha: widget.goal.feasibility.ringAlpha);

    return SizedBox(
      key: const ValueKey('goalProgressRing'),
      width: 96,
      height: 96,
      child: AnimatedBuilder(
        animation: _value,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(96),
              painter: _RingPainter(progress: _value.value, color: color),
            ),
            Text(
              '${(_value.value * 100).round()}%',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  static const _strokeWidth = 10.0;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - _strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawArc(rect, 0, 6.2832, false, trackPaint);

    if (progress <= 0.001) return;
    const startAngle = -1.5708; // -90 degrees
    final fillPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 6.2832,
        transform: const GradientRotation(startAngle),
        colors: [color.withValues(alpha: 0.55), color],
        stops: const [0.0, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, 6.2832 * progress, false, fillPaint);

    // A bright cap at the leading edge reads as a glossier, more modern
    // ring than a flat stroke end.
    final tipAngle = startAngle + 6.2832 * progress;
    final tipCenter = Offset(
      center.dx + radius * math.cos(tipAngle),
      center.dy + radius * math.sin(tipAngle),
    );
    canvas.drawCircle(tipCenter, _strokeWidth / 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Full projection breakdown, opened by tapping the hero card.
class _ProjectionDetailSheet extends StatelessWidget {
  final AcademicStanding standing;
  final GradingScheme scheme;
  final TargetProjection? goal;
  final ClassificationBand? goalBand;

  const _ProjectionDetailSheet({
    required this.standing,
    required this.scheme,
    required this.goal,
    required this.goalBand,
  });

  @override
  Widget build(BuildContext context) {
    final goal = this.goal;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Projection breakdown',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Current CGPA', value: _fmt(standing.cgpa)),
            _DetailRow(
              label: 'Classification',
              value: standing.classification?.label ?? 'Not yet classified',
            ),
            if (goal != null) ...[
              _DetailRow(label: 'Goal', value: goalBand?.label ?? goal.targetLabel ?? '—'),
              _DetailRow(
                label: 'Required average',
                value: goal.requiredAverage != null ? _fmt(goal.requiredAverage!) : 'N/A',
              ),
              _DetailRow(label: 'Semesters remaining', value: '${goal.semestersRemaining}'),
              _DetailRow(
                label: 'Personal best semester',
                value: goal.personalBest != null ? _fmt(goal.personalBest!) : '—',
              ),
              _DetailRow(label: 'Feasibility', value: goal.feasibility.ringLabel),
              _DetailRow(label: 'Ceiling if maxed out', value: _fmt(goal.ceilingCgpa)),
              _DetailRow(label: 'If pace holds', value: _fmt(goal.coastingCgpa)),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No goal set yet.'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: OnboardingLightPalette.secondaryText)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

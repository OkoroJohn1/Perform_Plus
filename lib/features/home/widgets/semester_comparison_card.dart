/// Semester-by-semester bars — replaces the reveal screen's fabricated
/// "Performance Breakdown" idea with something genuinely computable: each
/// semester's own GPA, coloured by whichever classification band it falls
/// into under the active scheme.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/models/grading_scheme.dart';

String _fmt(double v) => v.toStringAsFixed(2);

class SemesterComparisonCard extends StatelessWidget {
  final AcademicStanding standing;
  final GradingScheme scheme;

  const SemesterComparisonCard({super.key, required this.standing, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final mostRecentFirst = standing.semesters.reversed.take(6).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GPA by Semester',
            style: TextStyle(
              color: context.palette.bodyText,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < mostRecentFirst.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _ComparisonBar(
              comp: mostRecentFirst[i],
              scheme: scheme,
              maxPoint: scheme.maxPoint,
              delay: Duration(milliseconds: 60 * i),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonBar extends StatefulWidget {
  final SemesterComputation comp;
  final GradingScheme scheme;
  final double maxPoint;
  final Duration delay;

  const _ComparisonBar({
    required this.comp,
    required this.scheme,
    required this.maxPoint,
    required this.delay,
  });

  @override
  State<_ComparisonBar> createState() => _ComparisonBarState();
}

class _ComparisonBarState extends State<_ComparisonBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fraction;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    final target = widget.maxPoint <= 0 ? 0.0 : (widget.comp.gpa / widget.maxPoint).clamp(0.0, 1.0);
    _fraction = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
        .drive(Tween(begin: 0.0, end: target));
    _startTimer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color get _fillColor {
    final band = widget.scheme.classify(widget.comp.gpa);
    if (band == null) return context.palette.secondaryText;
    final index = widget.scheme.bandsDescending.indexWhere((b) => b.label == band.label);
    return ClassificationPalette.colorForBandIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final color = _fillColor;
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            widget.comp.shortLabel,
            style: TextStyle(
              color: context.palette.bodyText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  const ColoredBox(color: DashboardPalette.barTrack),
                  AnimatedBuilder(
                    animation: _fraction,
                    builder: (context, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _fraction.value,
                      child: ColoredBox(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            _fmt(widget.comp.gpa),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: context.palette.bodyText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

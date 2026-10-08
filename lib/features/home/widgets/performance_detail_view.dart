/// Full-screen breakdown for the Dashboard's "Performance View" (3D bar)
/// card -- opened by tapping it. A bigger version of the same blocks (every
/// semester, not just the last six the card fits) plus a scrollable
/// per-semester list underneath, over a blurred dashboard background. Same
/// spin-pop-open/blur/Material pattern as `trend_detail_view.dart`'s CGPA
/// trend breakdown, factored through `spin_pop_dialog.dart` so the two
/// can't drift apart.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/performance_flag.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';
import '../../../shared/widgets/spin_pop_dialog.dart';
import 'trend_3d_chart.dart';

Future<void> showPerformanceDetail(
  BuildContext context, {
  required AcademicStanding standing,
  required GradingScheme scheme,
}) {
  return showSpinPopDetail(
    context,
    builder: (context) => PerformanceDetailView(standing: standing, scheme: scheme),
  );
}

class PerformanceDetailView extends StatefulWidget {
  final AcademicStanding standing;
  final GradingScheme scheme;

  const PerformanceDetailView({super.key, required this.standing, required this.scheme});

  @override
  State<PerformanceDetailView> createState() => _PerformanceDetailViewState();
}

class _PerformanceDetailViewState extends State<PerformanceDetailView> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final semesters = widget.standing.semesters.where((s) => s.creditUnits > 0).toList();
    final maxPoint = widget.scheme.maxPoint;

    return Stack(
      fit: StackFit.expand,
      children: [
        const SpinPopScrim(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 40, offset: const Offset(0, 16)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              // Same "no Material ancestor here" fix as the CGPA trend
              // detail -- `showGeneralDialog` content sits outside any
              // Material/Scaffold, so every Text would otherwise fall back
              // to Flutter's debug double-underline style.
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Performance View',
                              style: TextStyle(color: palette.bodyText, fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('performanceDetailCloseTap'),
                            icon: Icon(Icons.close, color: palette.secondaryText),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Every semester\'s GPA, block by block.',
                        style: TextStyle(color: palette.secondaryText, fontSize: 13.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (semesters.length < 2)
                      Expanded(
                        child: Center(
                          child: Text(
                            'Add one more semester to see this view',
                            style: TextStyle(color: palette.secondaryText, fontSize: 15),
                          ),
                        ),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          height: 220,
                          child: AnimatedBuilder(
                            animation: _grow,
                            builder: (context, _) => CustomPaint(
                              size: Size.infinite,
                              painter: Bars3DPainter(
                                semesters: semesters,
                                maxPoint: maxPoint,
                                colorFor: (gpa) => colorForGpa(widget.scheme, gpa),
                                grow: _grow.value,
                                labelColor: palette.bodyText,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Divider(height: 1, color: palette.divider),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          itemCount: semesters.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: palette.divider),
                          itemBuilder: (context, i) {
                            final comp = semesters[i];
                            final color = colorForGpa(widget.scheme, comp.gpa);
                            final band = widget.scheme.classify(comp.gpa);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${comp.level}L',
                                      style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${comp.term.shortLabel} · ${comp.creditUnits}cr',
                                          style: TextStyle(color: palette.bodyText, fontSize: 14.5, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          band?.shortLabel ?? 'Not yet classified',
                                          style: TextStyle(color: palette.secondaryText, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    fmtGpa(comp.gpa),
                                    style: TextStyle(
                                      color: performanceColor(comp.gpa, normal: palette.bodyText),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

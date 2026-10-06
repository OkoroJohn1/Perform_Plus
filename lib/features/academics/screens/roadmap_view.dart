/// Roadmap — a level-by-level view of the programme, plus a "simulate the
/// future" tool. Rebuilt onto the same `#F7F7FB`/`OnboardingLightPalette`
/// surface as the rest of the Academics tab (see `results_view.dart`).
///
/// ⚠ FIXED: this screen used to read `Theme.of(context).textTheme`, which
/// resolves to the app's OLD dark-glass `ThemeData` (white text) — sitting
/// on `academics_shell.dart`'s light `#F7F7FB` background, that rendered as
/// white-on-white, i.e. invisible. Every colour here is now hardcoded to
/// `OnboardingLightPalette`, matching every other rebuilt screen, instead of
/// depending on which `ThemeData` happens to be ambient.
///
/// A level only shows fully complete once BOTH terms have a semester on
/// record — one term alone is a real but partial state, not "done."
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/performance_flag.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/engine/projection_solver.dart';
import '../../../domain/models/course_result.dart';
import '../../auth/providers/profile_provider.dart';

String _fmt(double v) => v.toStringAsFixed(2);

enum _LevelStatus { complete, partial, current, upcoming }

class RoadmapView extends ConsumerWidget {
  const RoadmapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standing = ref.watch(standingProvider);
    final profile = ref.watch(studentProfileProvider);

    if (!standing.hasData) {
      return const _EmptyRoadmap();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Level Roadmap',
                style: TextStyle(color: context.palette.bodyText, fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            _SimulateButton(onTap: () => _showSimulateSheet(context, ref, standing, profile)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Your programme, one level at a time',
          style: TextStyle(color: context.palette.secondaryText, fontSize: 14.5),
        ),
        const SizedBox(height: 20),
        for (final level in AppConstants.levels)
          _LevelCard(
            level: level,
            semesters: standing.semesters.where((s) => s.level == level).toList(),
            isCurrent: profile?.currentLevel == level,
            isLast: level == AppConstants.levels.last,
          ),
      ],
    );
  }

  void _showSimulateSheet(
    BuildContext context,
    WidgetRef ref,
    AcademicStanding standing,
    StudentProfile? profile,
  ) {
    final scheme = ref.read(academicRecordProvider).scheme;
    final defaultRemaining =
        profile != null ? semestersRemainingFor(profile).clamp(1, 8) : 1;
    var semestersRemaining = defaultRemaining;
    var assumedGpa = standing.cgpa;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) {
          final projection = ProjectionSolver.simulate(
            standing: standing,
            scheme: scheme,
            assumedGpa: assumedGpa,
            semestersRemaining: semestersRemaining,
          );

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulate your future',
                  style: TextStyle(color: context.palette.bodyText, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'A sustained GPA across a chosen number of semesters -- never a probability, just honest arithmetic on your own record.',
                  style: TextStyle(color: context.palette.secondaryText, fontSize: 13.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'For how many semesters?',
                  style: TextStyle(color: context.palette.bodyText, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final n in {1, 2, 4, defaultRemaining}.where((n) => n > 0).toList()..sort())
                      _SemesterChip(
                        label: n == defaultRemaining ? 'Rest ($n)' : '$n',
                        selected: semestersRemaining == n,
                        onTap: () => setState(() => semestersRemaining = n),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'If your GPA is ${_fmt(assumedGpa)} each semester:',
                  style: TextStyle(color: context.palette.bodyText, fontSize: 14.5, fontWeight: FontWeight.w500),
                ),
                SliderTheme(
                  data: SliderTheme.of(sheetContext).copyWith(
                    activeTrackColor: context.palette.primary,
                    thumbColor: context.palette.primary,
                    inactiveTrackColor: context.palette.surfaceBorder,
                  ),
                  child: Slider(
                    value: assumedGpa.clamp(0, scheme.maxPoint),
                    min: 0,
                    max: scheme.maxPoint,
                    divisions: (scheme.maxPoint * 20).round(),
                    label: _fmt(assumedGpa),
                    onChanged: (v) => setState(() => assumedGpa = v),
                  ),
                ),
                const SizedBox(height: 12),
                _ProjectionResultCard(standing: standing, projection: projection),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SimulateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SimulateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.palette.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_graph, size: 17, color: context.palette.primary),
            const SizedBox(width: 6),
            Text(
              'Simulate',
              style: TextStyle(color: context.palette.primary, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemesterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SemesterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.palette.primary : context.palette.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : context.palette.bodyText,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ProjectionResultCard extends StatelessWidget {
  final AcademicStanding standing;
  final ForwardProjection projection;

  const _ProjectionResultCard({required this.standing, required this.projection});

  @override
  Widget build(BuildContext context) {
    final rising = projection.deltaFromCurrent >= 0;
    final barMax = [standing.cgpa, projection.projectedCgpa, 5.0].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniBar(label: 'Now', value: standing.cgpa, max: barMax, color: context.palette.secondaryText),
          const SizedBox(height: 10),
          _MiniBar(
            label: 'Projected',
            value: projection.projectedCgpa,
            max: barMax,
            color: context.palette.primary,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                rising ? Icons.trending_up : Icons.trending_down,
                size: 18,
                color: rising ? context.palette.success : context.palette.amber,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rising
                      ? 'Up ${_fmt(projection.deltaFromCurrent)} from your current CGPA'
                      : 'Down ${_fmt(-projection.deltaFromCurrent)} from your current CGPA',
                  style: TextStyle(
                    color: rising ? context.palette.success : context.palette.amber,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (projection.projectedClassification != null) ...[
            const SizedBox(height: 6),
            Text(
              'Lands in ${projection.projectedClassification!.label}',
              style: TextStyle(color: context.palette.secondaryText, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;

  const _MiniBar({required this.label, required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 66,
          child: Text(label, style: TextStyle(color: context.palette.secondaryText, fontSize: 12.5)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  const ColoredBox(color: DashboardPalette.barTrack),
                  FractionallySizedBox(
                    widthFactor: max <= 0 ? 0 : (value / max).clamp(0.0, 1.0),
                    child: ColoredBox(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            _fmt(value),
            textAlign: TextAlign.right,
            style: TextStyle(color: context.palette.bodyText, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _EmptyRoadmap extends StatelessWidget {
  const _EmptyRoadmap();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timeline_outlined, size: 48, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              'No roadmap yet',
              style: TextStyle(color: context.palette.bodyText, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Add results to see your progress across levels.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.secondaryText, fontSize: 15.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int level;
  final List<SemesterComputation> semesters;
  final bool isCurrent;
  final bool isLast;

  const _LevelCard({
    required this.level,
    required this.semesters,
    required this.isCurrent,
    required this.isLast,
  });

  _LevelStatus get _status {
    final hasFirst = semesters.any((s) => s.term == SemesterTerm.first);
    final hasSecond = semesters.any((s) => s.term == SemesterTerm.second);
    if (hasFirst && hasSecond) return _LevelStatus.complete;
    if (hasFirst || hasSecond) return _LevelStatus.partial;
    if (isCurrent) return _LevelStatus.current;
    return _LevelStatus.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final (icon, dotColor) = switch (status) {
      _LevelStatus.complete => (Icons.check_circle, context.palette.success),
      _LevelStatus.partial => (Icons.adjust, context.palette.amber),
      _LevelStatus.current => (Icons.radio_button_checked, context.palette.primary),
      _LevelStatus.upcoming => (Icons.circle_outlined, const Color(0xFFD1D5DB)),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, color: dotColor, size: 22),
              if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFECECF1))),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: isCurrent ? Border.all(color: context.palette.primary, width: 1.4) : null,
                  boxShadow: [
                    BoxShadow(
                      color: context.palette.bodyText.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$level Level',
                            style: TextStyle(
                              color: context.palette.bodyText,
                              fontSize: 16,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _statusLabel(status),
                            style: TextStyle(color: _statusLabelColor(context, status), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    if (semesters.isNotEmpty)
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final s in semesters)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: performanceColor(s.gpa, normal: context.palette.primary)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _fmt(s.gpa),
                                style: TextStyle(
                                  color: performanceColor(s.gpa, normal: context.palette.primary),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(_LevelStatus status) => switch (status) {
        _LevelStatus.complete => 'Both semesters uploaded',
        _LevelStatus.partial => '1 of 2 semesters uploaded',
        _LevelStatus.current => 'Current level',
        _LevelStatus.upcoming => 'Upcoming',
      };

  Color _statusLabelColor(BuildContext context, _LevelStatus status) => switch (status) {
        _LevelStatus.complete => context.palette.success,
        _LevelStatus.partial => context.palette.amber,
        _LevelStatus.current => context.palette.primary,
        _LevelStatus.upcoming => context.palette.secondaryText,
      };
}

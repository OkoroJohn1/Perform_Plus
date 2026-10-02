/// Four compact facts — every one read straight off [AcademicStanding]
/// (plus the raw semester list for a course count, which the computed
/// standing doesn't carry). None is a proxy for something uncomputable.
///
/// Rendered as a single frosted-glass bar that floats over the bottom edge
/// of the CGPA hero card (see `dashboard_screen.dart`'s `Stack`) — the one
/// place on this screen a glass treatment earns its keep, since it's the
/// one card with something colourful behind it to actually blur.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/models/course_result.dart';

String _fmt(double v) => v.toStringAsFixed(2);

class QuickStatsRow extends StatelessWidget {
  final AcademicStanding standing;
  final List<Semester> rawSemesters;

  const QuickStatsRow({super.key, required this.standing, required this.rawSemesters});

  @override
  Widget build(BuildContext context) {
    final best = standing.bestSemesterGpa;
    final totalCourses = rawSemesters.fold<int>(0, (sum, s) => sum + s.results.length);

    final cells = [
      (icon: Icons.calendar_month_outlined, value: '${standing.semesters.length}', label: 'Semesters'),
      (icon: Icons.menu_book_outlined, value: '$totalCourses', label: 'Courses'),
      (icon: Icons.school_outlined, value: '${standing.totalCreditUnits}', label: 'Credits'),
      (icon: Icons.trending_up, value: best == null ? '—' : _fmt(best), label: 'Best sem.'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        // Sits directly on the Dashboard, the most-visited screen -- lower
        // sigma is meaningfully cheaper (cost scales ~sigma^2) and still
        // reads as frosted glass over the gradient hero card behind it.
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.3),
            boxShadow: [
              BoxShadow(
                color: OnboardingLightPalette.bodyText.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 34,
                    color: OnboardingLightPalette.searchBorder,
                  ),
                Expanded(child: _StatCell(cells[i])),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final ({IconData icon, String value, String label}) data;

  const _StatCell(this.data);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(data.icon, size: 17, color: context.palette.primary),
        const SizedBox(height: 6),
        Text(
          data.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: OnboardingLightPalette.bodyText,
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          data.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: OnboardingLightPalette.secondaryText, fontSize: 11, height: 1.1),
        ),
      ],
    );
  }
}

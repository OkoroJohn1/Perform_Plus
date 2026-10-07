/// Per-semester course ranking, strongest grade to weakest — answers
/// "which of my actual courses are pulling my average down" at a glance,
/// grouped by semester since the same course code can appear more than
/// once across attempts. Real arithmetic over [CourseResult.grade] via
/// [GradingScheme.pointForLetter]; nothing invented, nothing routed through
/// an LLM. A course whose grade isn't recognised by the active scheme is
/// skipped here (never silently ranked as if it scored zero) — the same
/// "never silently zero an unrecognised grade" rule the engine itself
/// follows, since this card isn't the place that already surfaces that as
/// a `CalculationIssue` (Academics' Results view is).
library;

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';

import 'package:flutter/material.dart';

class _RankedCourse {
  final CourseResult result;
  final double point;

  const _RankedCourse({required this.result, required this.point});
}

class _SemesterStrength {
  final Semester semester;
  final List<_RankedCourse> ranked;

  const _SemesterStrength({required this.semester, required this.ranked});
}

class CourseStrengthCard extends StatelessWidget {
  final AcademicStanding standing;
  final GradingScheme scheme;
  final List<Semester> rawSemesters;

  const CourseStrengthCard({
    super.key,
    required this.standing,
    required this.scheme,
    required this.rawSemesters,
  });

  @override
  Widget build(BuildContext context) {
    final excludedIds = <String>{};
    for (final comp in standing.semesters) {
      excludedIds.addAll(comp.excluded.map((e) => e.resultId));
    }

    final ordered = [...rawSemesters]..sort((a, b) => b.sortKey.compareTo(a.sortKey));

    final entries = <_SemesterStrength>[];
    for (final semester in ordered) {
      final ranked = <_RankedCourse>[];
      for (final result in semester.results) {
        if (excludedIds.contains(result.id)) continue;
        final point = scheme.pointForLetter(result.grade);
        if (point == null) continue;
        ranked.add(_RankedCourse(result: result, point: point));
      }
      if (ranked.isEmpty) continue;
      ranked.sort((a, b) {
        final cmp = b.point.compareTo(a.point);
        return cmp != 0 ? cmp : a.result.courseCode.compareTo(b.result.courseCode);
      });
      entries.add(_SemesterStrength(semester: semester, ranked: ranked));
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course strength',
            style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Strongest to weakest, by semester.',
            style: TextStyle(color: context.palette.secondaryText, fontSize: 14),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.palette.divider),
            _SemesterStrengthAccordion(entry: entries[i], initiallyExpanded: i == 0),
          ],
        ],
      ),
    );
  }
}

class _SemesterStrengthAccordion extends StatefulWidget {
  final _SemesterStrength entry;
  final bool initiallyExpanded;

  const _SemesterStrengthAccordion({required this.entry, required this.initiallyExpanded});

  @override
  State<_SemesterStrengthAccordion> createState() => _SemesterStrengthAccordionState();
}

class _SemesterStrengthAccordionState extends State<_SemesterStrengthAccordion> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final semester = widget.entry.semester;
    final ranked = widget.entry.ranked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: ValueKey('courseStrengthToggle-${semester.id}'),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    semester.shortLabel,
                    style: TextStyle(color: context.palette.bodyText, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${ranked.length} course${ranked.length == 1 ? '' : 's'}',
                  style: TextStyle(color: context.palette.secondaryText, fontSize: 13),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: _expanded ? 0.5 : 0,
                  child: Icon(Icons.keyboard_arrow_down, size: 22, color: context.palette.hintText),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      for (var i = 0; i < ranked.length; i++) _CourseStrengthRow(rank: i + 1, course: ranked[i]),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _CourseStrengthRow extends StatelessWidget {
  final int rank;
  final _RankedCourse course;

  const _CourseStrengthRow({required this.rank, required this.course});

  @override
  Widget build(BuildContext context) {
    final result = course.result;
    final gradeColor = ClassificationPalette.forGradeLetter(result.grade);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: TextStyle(color: context.palette.hintText, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.courseCode,
                  style: TextStyle(color: context.palette.bodyText, fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                if (result.courseTitle != null)
                  Text(
                    result.courseTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.palette.secondaryText, fontSize: 12.5),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result.grade,
              style: TextStyle(color: gradeColor, fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

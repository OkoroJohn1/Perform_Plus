/// Results — the Academics tab's default view, and the record of truth for
/// "where do I stand."
///
/// Every number comes from [CgpaEngine]/[AcademicStanding], read through
/// [academicRecordProvider] — never from onboarding state. The one label
/// fix that matters most: a semester row shows BOTH that semester's own GPA
/// and the running CGPA at that point in time, never one number under the
/// wrong name. See `_SemesterRow`.
library;

import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/performance_flag.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/seed/nigerian_institutions.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';
import '../widgets/add_semester_sheet.dart' show showAddSemesterSheet, showEditCourseSheet;

String _fmt(double v) => v.toStringAsFixed(2);

/// A single (course code, all its attempts across the whole record) group.
/// An attempt-1-only failing course is still a carryover candidate — it
/// hasn't been retaken yet, but it needs retaking.
class _CarryoverEntry {
  final String courseCode;
  final List<({Semester semester, CourseResult result})> attempts;

  const _CarryoverEntry({required this.courseCode, required this.attempts});

  bool isCleared(GradingScheme scheme) {
    final latest = attempts.last.result;
    return !scheme.isFailingLetter(latest.grade);
  }
}

class ResultsView extends ConsumerStatefulWidget {
  const ResultsView({super.key});

  @override
  ConsumerState<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends ConsumerState<ResultsView> {
  bool _newestFirst = true;

  @override
  Widget build(BuildContext context) {
    final standing = ref.watch(standingProvider);
    final record = ref.watch(academicRecordProvider);
    final scheme = record.scheme;
    final rawSemesters = record.semesters;

    if (!standing.hasData) return const _EmptyResults();

    ({int level, SemesterTerm term}) nextExpected() {
      final latest = rawSemesters.reduce((a, b) => a.sortKey > b.sortKey ? a : b);
      if (latest.term == SemesterTerm.first) {
        return (level: latest.level, term: SemesterTerm.second);
      }
      return (level: latest.level + 100, term: SemesterTerm.first);
    }

    final next = nextExpected();

    return RefreshIndicator(
      onRefresh: () => ref.read(academicRecordProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _StandingCard(standing: standing, scheme: scheme, rawSemesters: rawSemesters),
          const SizedBox(height: 24),
          _SemesterListHeader(
            newestFirst: _newestFirst,
            onToggle: () => setState(() => _newestFirst = !_newestFirst),
          ),
          const SizedBox(height: 12),
          _SemesterList(
            standing: standing,
            scheme: scheme,
            rawSemesters: rawSemesters,
            newestFirst: _newestFirst,
          ),
          const SizedBox(height: 20),
          _AddSemesterButton(
            onPressed: () => showAddSemesterSheet(
              context,
              initialLevel: next.level,
              initialTerm: next.term,
              onEditExisting: (id) => _openSemesterDetail(context, scheme, id),
            ),
          ),
          const SizedBox(height: 20),
          _PerformanceSummaryCard(standing: standing),
          const SizedBox(height: 20),
          _GradeBreakdownCard(standing: standing, rawSemesters: rawSemesters, scheme: scheme),
          if (_hasCarryovers(rawSemesters, scheme)) ...[
            const SizedBox(height: 20),
            _CarryoverCard(rawSemesters: rawSemesters, scheme: scheme),
          ],
        ],
      ),
    );
  }
}

bool _hasCarryovers(List<Semester> rawSemesters, GradingScheme scheme) {
  final byCode = <String, List<CourseResult>>{};
  for (final s in rawSemesters) {
    for (final r in s.results) {
      byCode.putIfAbsent(r.courseCode, () => []).add(r);
    }
  }
  return byCode.values.any(
    (results) => results.length > 1 || scheme.isFailingLetter(results.single.grade),
  );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [palette.primary.withValues(alpha: 0.16), palette.primary.withValues(alpha: 0.04)],
                ),
              ),
              child: Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(Icons.school_outlined, size: 34, color: palette.primary),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No results yet',
              style: TextStyle(color: palette.bodyText, fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                'Add your first semester and your classification, carryovers and roadmap all show up right here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.secondaryText, fontSize: 15, height: 1.4),
              ),
            ),
            const SizedBox(height: 28),
            _AddSemesterButton(onPressed: () => showAddSemesterSheet(context)),
          ],
        ),
      ),
    );
  }
}

/// Current CGPA and classification, plus the composition of the record —
/// deliberately NOT a repeat of the dashboard hero's goal ring. That ring
/// belongs to the dashboard; this card's job is composition, not goals.
class _StandingCard extends StatelessWidget {
  final AcademicStanding standing;
  final GradingScheme scheme;
  final List<Semester> rawSemesters;

  const _StandingCard({required this.standing, required this.scheme, required this.rawSemesters});

  @override
  Widget build(BuildContext context) {
    final totalCourses = rawSemesters.fold<int>(0, (sum, s) => sum + s.results.length);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [context.palette.primaryGradientStart, context.palette.primaryGradientEnd],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.grade_outlined, size: 16, color: Colors.white.withValues(alpha: 0.78)),
                        const SizedBox(width: 6),
                        Text(
                          'Current CGPA',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fmt(standing.cgpa),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    if (standing.cgpa < lowPerformanceThreshold) ...[
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
                    const SizedBox(height: 4),
                    Text(
                      standing.classification?.shortLabel ?? 'Not yet classified',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: -22,
                child: _GlassMiniStatBar(
                  semesters: standing.semesters.length,
                  courses: totalCourses,
                  creditUnits: standing.totalCreditUnits,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 36, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 1, color: context.palette.divider),
                const SizedBox(height: 16),
                _CreditSplitBar(rawSemesters: rawSemesters, standing: standing),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The one place a glass treatment earns its keep in this card -- it floats
/// over the gradient hero above, which is the only part of this card with
/// something colourful behind it to actually blur.
class _GlassMiniStatBar extends StatelessWidget {
  final int semesters;
  final int courses;
  final int creditUnits;

  const _GlassMiniStatBar({required this.semesters, required this.courses, required this.creditUnits});

  @override
  Widget build(BuildContext context) {
    final cells = [
      (icon: Icons.calendar_month_outlined, value: '$semesters', label: 'Semesters'),
      (icon: Icons.menu_book_outlined, value: '$courses', label: 'Courses'),
      (icon: Icons.school_outlined, value: '$creditUnits', label: 'Credit units'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: context.palette.surface.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.palette.surface.withValues(alpha: 0.65), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: context.palette.bodyText.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0) Container(width: 1, height: 30, color: context.palette.surfaceBorder),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cells[i].icon, size: 16, color: context.palette.primary),
                      const SizedBox(height: 4),
                      Text(
                        cells[i].value,
                        style: TextStyle(color: context.palette.bodyText, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        cells[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.palette.secondaryText, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditSplitBar extends StatelessWidget {
  final List<Semester> rawSemesters;
  final AcademicStanding standing;

  const _CreditSplitBar({required this.rawSemesters, required this.standing});

  @override
  Widget build(BuildContext context) {
    final excludedIds = <String>{};
    for (final comp in standing.semesters) {
      excludedIds.addAll(comp.excluded.map((e) => e.resultId));
    }

    final unitsByLetter = <String, int>{};
    for (final s in rawSemesters) {
      for (final r in s.results) {
        if (excludedIds.contains(r.id)) continue;
        final letter = r.grade.trim().toUpperCase();
        unitsByLetter[letter] = (unitsByLetter[letter] ?? 0) + r.creditUnit;
      }
    }

    if (unitsByLetter.isEmpty) return const SizedBox.shrink();

    final letters = unitsByLetter.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    final total = unitsByLetter.values.fold<int>(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 20,
            child: Row(
              children: [
                for (final letter in letters)
                  if (total > 0)
                    Expanded(
                      flex: unitsByLetter[letter]!,
                      child: ColoredBox(color: ClassificationPalette.forGradeLetter(letter)),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final letter in letters)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ClassificationPalette.forGradeLetter(letter),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${unitsByLetter[letter]} at $letter',
                    style: TextStyle(color: context.palette.secondaryText, fontSize: 12.5),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Per-semester grade tables -- the aggregate `_CreditSplitBar` above
/// answers "what does my whole record look like," this answers "what did
/// THIS semester look like," one collapsible row per semester so the
/// screen doesn't have to show every table at once.
class _GradeBreakdownCard extends StatelessWidget {
  final AcademicStanding standing;
  final List<Semester> rawSemesters;
  final GradingScheme scheme;

  const _GradeBreakdownCard({required this.standing, required this.rawSemesters, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final ordered = standing.semesters.reversed.toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.palette.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.table_chart_outlined, size: 18, color: context.palette.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grade Breakdown',
                      style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Tap a semester to see its grade table',
                      style: TextStyle(color: context.palette.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final comp in ordered)
            _SemesterAccordion(
              comp: comp,
              raw: rawSemesters.firstWhere((s) => s.id == comp.semesterId),
              scheme: scheme,
            ),
        ],
      ),
    );
  }
}

class _GradeRow {
  final String letter;
  final int courses;
  final int units;
  final double points;

  const _GradeRow({required this.letter, required this.courses, required this.units, required this.points});
}

class _SemesterAccordion extends StatefulWidget {
  final SemesterComputation comp;
  final Semester raw;
  final GradingScheme scheme;

  const _SemesterAccordion({required this.comp, required this.raw, required this.scheme});

  @override
  State<_SemesterAccordion> createState() => _SemesterAccordionState();
}

class _SemesterAccordionState extends State<_SemesterAccordion> {
  bool _expanded = false;

  List<_GradeRow> _rows() {
    final excludedIds = widget.comp.excluded.map((e) => e.resultId).toSet();
    final byLetter = <String, List<CourseResult>>{};
    for (final r in widget.raw.results) {
      if (excludedIds.contains(r.id)) continue;
      byLetter.putIfAbsent(r.grade.trim().toUpperCase(), () => []).add(r);
    }
    final letters = byLetter.keys.toList()..sort();
    return [
      for (final letter in letters)
        _GradeRow(
          letter: letter,
          courses: byLetter[letter]!.length,
          units: byLetter[letter]!.fold(0, (a, r) => a + r.creditUnit),
          points: byLetter[letter]!.fold(
            0.0,
            (a, r) => a + (widget.scheme.pointForLetter(letter) ?? 0) * r.creditUnit,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final comp = widget.comp;
    final rows = _rows();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: ValueKey('gradeBreakdownToggle-${widget.raw.id}'),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: context.palette.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${comp.level}L',
                    style: TextStyle(color: context.palette.primary, fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.scheme.termLabel(comp.term),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.palette.bodyText, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  'GPA ${_fmt(comp.gpa)}',
                  style: TextStyle(
                    color: performanceColor(comp.gpa, normal: context.palette.secondaryText),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
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
          child: _expanded ? _GradeTable(rows: rows) : const SizedBox(width: double.infinity),
        ),
        Divider(height: 1, color: context.palette.divider),
      ],
    );
  }
}

class _GradeTable extends StatelessWidget {
  final List<_GradeRow> rows;

  const _GradeTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.palette.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('Grade', style: TextStyle(color: context.palette.secondaryText, fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Courses', style: TextStyle(color: context.palette.secondaryText, fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Units', style: TextStyle(color: context.palette.secondaryText, fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Points', style: TextStyle(color: context.palette.secondaryText, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ],
            ),
          ),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ClassificationPalette.forGradeLetter(row.letter).withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        row.letter,
                        style: TextStyle(
                          color: ClassificationPalette.forGradeLetter(row.letter),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text('${row.courses}', style: TextStyle(color: context.palette.bodyText, fontSize: 14)),
                  ),
                  Expanded(
                    child: Text('${row.units}', style: TextStyle(color: context.palette.bodyText, fontSize: 14)),
                  ),
                  Expanded(
                    child: Text(
                      row.points.toStringAsFixed(0),
                      textAlign: TextAlign.right,
                      style: TextStyle(color: context.palette.bodyText, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SemesterListHeader extends StatelessWidget {
  final bool newestFirst;
  final VoidCallback onToggle;

  const _SemesterListHeader({required this.newestFirst, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(Icons.event_note_outlined, size: 20, color: context.palette.bodyText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Semesters',
              style: TextStyle(color: context.palette.bodyText, fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton.icon(
            onPressed: onToggle,
            icon: Icon(Icons.swap_vert, size: 17, color: context.palette.primary),
            label: Text(
              newestFirst ? 'Newest first' : 'Oldest first',
              style: TextStyle(color: context.palette.primary, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemesterEntry {
  final SemesterComputation comp;
  final Semester raw;
  final double cgpaThen;
  final double? previousGpa;

  const _SemesterEntry({
    required this.comp,
    required this.raw,
    required this.cgpaThen,
    required this.previousGpa,
  });
}

class _SemesterList extends StatelessWidget {
  final AcademicStanding standing;
  final GradingScheme scheme;
  final List<Semester> rawSemesters;
  final bool newestFirst;

  const _SemesterList({
    required this.standing,
    required this.scheme,
    required this.rawSemesters,
    required this.newestFirst,
  });

  @override
  Widget build(BuildContext context) {
    final trend = standing.cumulativeCgpaTrend;
    final entries = <_SemesterEntry>[
      for (var i = 0; i < standing.semesters.length; i++)
        _SemesterEntry(
          comp: standing.semesters[i],
          raw: rawSemesters.firstWhere((s) => s.id == standing.semesters[i].semesterId),
          cgpaThen: trend[i],
          previousGpa: i > 0 ? standing.semesters[i - 1].gpa : null,
        ),
    ];
    final ordered = newestFirst ? entries.reversed.toList() : entries;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showCgpaThen = constraints.maxWidth >= 340;
          return Column(
            children: [
              for (var i = 0; i < ordered.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 72, color: context.palette.divider),
                _SemesterRow(
                  entry: ordered[i],
                  scheme: scheme,
                  showCgpaThen: showCgpaThen,
                  showDelta: standing.semesters.length >= 2,
                  onTap: () => _openSemesterDetail(context, scheme, ordered[i].raw.id),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SemesterRow extends StatelessWidget {
  final _SemesterEntry entry;
  final GradingScheme scheme;
  final bool showCgpaThen;
  final bool showDelta;
  final VoidCallback onTap;

  const _SemesterRow({
    required this.entry,
    required this.scheme,
    required this.showCgpaThen,
    required this.showDelta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final comp = entry.comp;
    final band = scheme.classify(comp.gpa);
    final bandIndex = band == null
        ? null
        : scheme.bandsDescending.indexWhere((b) => b.label == band.label);
    final barColor = bandIndex == null
        ? context.palette.secondaryText
        : ClassificationPalette.colorForBandIndex(bandIndex);

    final delta = showDelta && entry.previousGpa != null
        ? CgpaEngine.round2(comp.gpa - entry.previousGpa!)
        : null;
    final showDeltaChip = delta != null && delta.abs() >= 0.05;

    return InkWell(
      key: ValueKey('semesterRowTap-${entry.raw.id}'),
      onTap: onTap,
      child: SizedBox(
        height: 76,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.palette.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${comp.level}L',
                        style: TextStyle(
                          color: context.palette.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scheme.termLabel(comp.term),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.palette.secondaryText, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              VerticalDivider(width: 1, color: context.palette.divider),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GPA', style: TextStyle(color: context.palette.secondaryText, fontSize: 13)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                _fmt(comp.gpa),
                                style: TextStyle(
                                  color: performanceColor(comp.gpa, normal: context.palette.bodyText),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (showDeltaChip) ...[
                                const SizedBox(width: 6),
                                _DeltaChip(delta: delta),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (showCgpaThen)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CGPA then', style: TextStyle(color: context.palette.secondaryText, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              _fmt(entry.cgpaThen),
                              style: TextStyle(
                                color: performanceColor(entry.cgpaThen, normal: context.palette.bodyText),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 6, height: 44, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 22, color: context.palette.hintText),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final double delta;

  const _DeltaChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    final rising = delta > 0;
    final color = rising ? context.palette.success : context.palette.amber;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(rising ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: color),
        Text(
          delta.abs().toStringAsFixed(2),
          style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _AddSemesterButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AddSemesterButton({required this.onPressed});

  @override
  State<_AddSemesterButton> createState() => _AddSemesterButtonState();
}

class _AddSemesterButtonState extends State<_AddSemesterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        key: const ValueKey('addSemesterButtonTap'),
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _pressed ? 0.98 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _pressed ? context.palette.primary : null,
              gradient: _pressed
                  ? null
                  : LinearGradient(
                      colors: [context.palette.primaryGradientStart, context.palette.primary],
                    ),
              boxShadow: [
                BoxShadow(
                  color: context.palette.primary.withValues(alpha: 0.22),
                  blurRadius: _pressed ? 4 : 16,
                  offset: _pressed ? Offset.zero : const Offset(0, 6),
                ),
                if (!_pressed)
                  BoxShadow(
                    color: context.palette.primary.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 20, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Add semester results',
                  style: TextStyle(color: Colors.white, fontSize: 17.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Four genuinely computable figures — replacing the mockup's "Average
/// CGPA" (meaningless: CGPA is already an average) and unsourced
/// "Improvement" tiles.
class _PerformanceSummaryCard extends StatelessWidget {
  final AcademicStanding standing;

  const _PerformanceSummaryCard({required this.standing});

  @override
  Widget build(BuildContext context) {
    final best = standing.bestSemesterGpa;
    final worst = standing.worstSemesterGpa;
    final trend = standing.semesters.length >= 2 ? standing.recentTrend(window: 3) : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your record',
            style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          // A `GridView.count` with a fixed `childAspectRatio` forces every
          // tile into an exact height regardless of its actual content --
          // at a larger system font-size setting (a common Android
          // accessibility choice, not an edge case) the tile's icon+value+
          // label column needs more height than that ratio allows, which is
          // exactly what threw the "bottom overflowed by N pixels" banner
          // here. `IntrinsicHeight` rows size each row to its tallest
          // tile's real content instead of guessing a ratio.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.trending_up,
                    value: best == null ? '—' : _fmt(best),
                    label: 'Best semester',
                    valueColor: best == null ? null : performanceColor(best, normal: context.palette.bodyText),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.trending_down,
                    value: worst == null ? '—' : _fmt(worst),
                    label: 'Lowest semester',
                    valueColor: worst == null ? null : performanceColor(worst, normal: context.palette.bodyText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.check_circle_outline,
                    value: '${standing.totalCreditsPassed}/${standing.totalCreditUnits}',
                    label: 'Credits passed',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: trend == null
                      ? const SizedBox()
                      : _SummaryTile(
                          icon: Icons.timeline,
                          value: '${trend >= 0 ? '+' : '−'}${trend.abs().toStringAsFixed(2)}',
                          label: 'Recent trend',
                          valueColor: trend > 0
                              ? context.palette.success
                              : trend < 0
                                  ? context.palette.amber
                                  : context.palette.secondaryText,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  const _SummaryTile({required this.icon, required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.palette.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: context.palette.primary),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? context.palette.bodyText,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.palette.secondaryText, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Absent from the mockup despite being central to the engine — a student
/// with a carryover deserves to see exactly how it's being counted, not
/// guess from a CGPA that moved in a way they didn't expect.
class _CarryoverCard extends StatelessWidget {
  final List<Semester> rawSemesters;
  final GradingScheme scheme;

  const _CarryoverCard({required this.rawSemesters, required this.scheme});

  List<_CarryoverEntry> _entries() {
    final byCode = <String, List<({Semester semester, CourseResult result})>>{};
    for (final s in rawSemesters) {
      for (final r in s.results) {
        byCode.putIfAbsent(r.courseCode, () => []).add((semester: s, result: r));
      }
    }

    final entries = <_CarryoverEntry>[];
    byCode.forEach((code, attempts) {
      final isCarryover =
          attempts.length > 1 || scheme.isFailingLetter(attempts.single.result.grade);
      if (!isCarryover) return;
      final sorted = [...attempts]..sort((a, b) => a.semester.sortKey.compareTo(b.semester.sortKey));
      entries.add(_CarryoverEntry(courseCode: code, attempts: sorted));
    });
    entries.sort((a, b) => a.courseCode.compareTo(b.courseCode));
    return entries;
  }

  String _policyNote(String institutionName) => switch (scheme.repeatPolicy) {
        RepeatPolicy.countBothAttempts =>
          "Both attempts count toward your CGPA under $institutionName's rules.",
        RepeatPolicy.replaceOriginal => 'Your retake replaces the original grade.',
        RepeatPolicy.replaceWithCap =>
          'Retakes are capped at ${scheme.repeatCapPoint?.toStringAsFixed(1) ?? '—'} points.',
      };

  @override
  Widget build(BuildContext context) {
    final entries = _entries();
    final institution = nigerianInstitutions.firstWhereOrNull((i) => i.id == scheme.institutionId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.replay, size: 20, color: context.palette.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Carryovers',
                  style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.palette.amber.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${entries.length}',
                  style: TextStyle(color: context.palette.amber, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _CarryoverRow(entry: entries[i], scheme: scheme),
          ],
          const SizedBox(height: 14),
          Text(
            _policyNote(institution?.name ?? scheme.name),
            style: TextStyle(color: context.palette.secondaryText, fontSize: 14),
          ),
          if (!scheme.isVerified) ...[
            const SizedBox(height: 6),
            Text(
              "We haven't confirmed ${institution?.abbreviation ?? scheme.name}'s carryover rule — "
              'check this against your department.',
              style: TextStyle(color: context.palette.amber, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _CarryoverRow extends StatelessWidget {
  final _CarryoverEntry entry;
  final GradingScheme scheme;

  const _CarryoverRow({required this.entry, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final cleared = entry.isCleared(scheme);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.courseCode,
                style: TextStyle(color: context.palette.bodyText, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in entry.attempts)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.palette.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${a.semester.level}L ${scheme.termLabel(a.semester.term)}: ${a.result.grade}',
                        style: TextStyle(color: context.palette.secondaryText, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        cleared
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: context.palette.success),
                  SizedBox(width: 4),
                  Text(
                    'Cleared',
                    style: TextStyle(color: context.palette.success, fontSize: 14.5, fontWeight: FontWeight.w500),
                  ),
                ],
              )
            : Text(
                'Outstanding',
                style: TextStyle(color: context.palette.amber, fontSize: 14.5, fontWeight: FontWeight.w500),
              ),
      ],
    );
  }
}

void _openSemesterDetail(BuildContext context, GradingScheme scheme, String semesterId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _SemesterDetailSheet(scheme: scheme, semesterId: semesterId),
  );
}

/// Shared by every mutation below — a cascade always shows the before/after
/// delta with an Undo, never a silent recalculation.
void _showRecalculationSnackBar(BuildContext context, WidgetRef ref, double before, VoidCallback undo) {
  final after = ref.read(standingProvider).cgpa;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('CGPA ${_fmt(before)} → ${_fmt(after)}'),
      action: SnackBarAction(label: 'Undo', onPressed: undo),
    ),
  );
}

class _SemesterDetailSheet extends ConsumerWidget {
  final GradingScheme scheme;
  final String semesterId;

  const _SemesterDetailSheet({required this.scheme, required this.semesterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(academicRecordProvider);
    final semester = record.semesters.firstWhereOrNull((s) => s.id == semesterId);

    if (semester == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final allResults = record.semesters.expand((s) => s.results).toList();
    final computation =
        CgpaEngine.computeSemester(semester: semester, scheme: scheme, allResults: allResults);

    void deleteCourse(CourseResult result) {
      final before = ref.read(standingProvider).cgpa;
      final updated =
          semester.copyWith(results: semester.results.where((r) => r.id != result.id).toList());
      ref.read(academicRecordProvider.notifier).updateSemester(updated);
      _showRecalculationSnackBar(
        context,
        ref,
        before,
        () => ref.read(academicRecordProvider.notifier).updateSemester(semester),
      );
    }

    // Full-row edit -- course code, credit unit AND grade, not just the
    // grade -- so a carryover entered with the wrong code/units can be
    // corrected without deleting and re-adding it.
    Future<void> editCourse(CourseResult result) async {
      final updatedResult = await showEditCourseSheet(context, scheme: scheme, initial: result);
      if (updatedResult == null || !context.mounted) return;

      final before = ref.read(standingProvider).cgpa;
      final updated = semester.copyWith(
        results: [for (final r in semester.results) r.id == result.id ? updatedResult : r],
      );
      ref.read(academicRecordProvider.notifier).updateSemester(updated);
      _showRecalculationSnackBar(
        context,
        ref,
        before,
        () => ref.read(academicRecordProvider.notifier).updateSemester(semester),
      );
    }

    // Covers a carryover discovered only after this semester was first
    // uploaded -- without this, the only way to add it was deleting the
    // whole semester and re-entering everything from scratch.
    Future<void> addCourse() async {
      final newResult = await showEditCourseSheet(context, scheme: scheme);
      if (newResult == null || !context.mounted) return;

      final before = ref.read(standingProvider).cgpa;
      final updated = semester.copyWith(
        results: [
          ...semester.results,
          CourseResult(
            id: newResult.id,
            semesterId: semester.id,
            courseCode: newResult.courseCode,
            courseTitle: newResult.courseTitle,
            creditUnit: newResult.creditUnit,
            grade: newResult.grade,
            source: newResult.source,
            extractionConfidence: newResult.extractionConfidence,
            createdAt: newResult.createdAt,
            updatedAt: newResult.updatedAt,
          ),
        ],
      );
      ref.read(academicRecordProvider.notifier).updateSemester(updated);
      _showRecalculationSnackBar(
        context,
        ref,
        before,
        () => ref.read(academicRecordProvider.notifier).updateSemester(semester),
      );
    }

    void deleteSemester() {
      final before = ref.read(standingProvider).cgpa;
      ref.read(academicRecordProvider.notifier).removeSemester(semester.id);
      Navigator.of(context).pop();
      _showRecalculationSnackBar(
        context,
        ref,
        before,
        () => ref.read(academicRecordProvider.notifier).addSemester(semester),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              '${semester.level}L · ${scheme.termLabel(semester.term)}',
              style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            for (final r in semester.results)
              _DetailCourseRow(
                result: r,
                scheme: scheme,
                onEdit: () => editCourse(r),
                onDelete: () => deleteCourse(r),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: addCourse,
                icon: Icon(Icons.add, color: context.palette.primary),
                label: Text(
                  'Add course',
                  style: TextStyle(color: context.palette.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Divider(height: 24, color: context.palette.divider),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(color: context.palette.bodyText, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${computation.qualityPoints.toStringAsFixed(0)} ÷ ${computation.creditUnits}',
                  style: TextStyle(color: context.palette.secondaryText, fontSize: 15),
                ),
                Text(
                  _fmt(computation.gpa),
                  style: TextStyle(color: context.palette.primary, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: deleteSemester,
                icon: Icon(Icons.delete_outline, color: context.palette.error),
                label: Text('Delete semester', style: TextStyle(color: context.palette.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCourseRow extends StatelessWidget {
  final CourseResult result;
  final GradingScheme scheme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DetailCourseRow({
    required this.result,
    required this.scheme,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final point = scheme.pointForLetter(result.grade) ?? 0;
    final qp = point * result.creditUnit;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(result.courseCode, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            flex: 3,
            child: Text(
              '${result.creditUnit} × ${point.toStringAsFixed(1)} (${result.grade})',
              style: TextStyle(color: context.palette.secondaryText, fontSize: 13.5),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(qp.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: context.palette.error),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

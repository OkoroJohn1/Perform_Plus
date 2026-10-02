/// Where a student's credit units actually sit, grouped by the grade
/// earned — real arithmetic over every counted [CourseResult], answering
/// "where am I actually losing points?" better than any invented metric.
/// Only shown once three or more semesters exist; a shorter record doesn't
/// have enough of a spread to make the split meaningful.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/models/course_result.dart';

/// Which of the five stacked-bar buckets a letter grade belongs to. Letters
/// outside FUTO's standard A-F scale fall into "Other" rather than being
/// silently dropped or mis-bucketed.
enum _GradeBucket { firstClass, upperSecond, lowerSecond, below, failed, other }

_GradeBucket _bucketFor(String letter) => switch (letter.trim().toUpperCase()) {
      'A' => _GradeBucket.firstClass,
      'B' => _GradeBucket.upperSecond,
      'C' => _GradeBucket.lowerSecond,
      'D' || 'E' => _GradeBucket.below,
      'F' => _GradeBucket.failed,
      _ => _GradeBucket.other,
    };

extension _BucketPresentation on _GradeBucket {
  Color colorFor(AppPalette palette) => switch (this) {
        _GradeBucket.firstClass => ClassificationPalette.gradeA,
        _GradeBucket.upperSecond => ClassificationPalette.gradeB,
        _GradeBucket.lowerSecond => ClassificationPalette.gradeC,
        _GradeBucket.below => ClassificationPalette.gradeBelow,
        _GradeBucket.failed => ClassificationPalette.gradeFailed,
        _GradeBucket.other => palette.secondaryText,
      };
}

class _LetterTotal {
  final String letter;
  final int units;
  const _LetterTotal(this.letter, this.units);
}

class CreditLoadSplitCard extends StatelessWidget {
  final AcademicStanding standing;
  final List<Semester> rawSemesters;

  const CreditLoadSplitCard({super.key, required this.standing, required this.rawSemesters});

  @override
  Widget build(BuildContext context) {
    if (rawSemesters.length < 3) return const SizedBox.shrink();

    final excludedIds = <String>{};
    for (final comp in standing.semesters) {
      excludedIds.addAll(comp.excluded.map((e) => e.resultId));
    }

    final unitsByLetter = <String, int>{};
    for (final semester in rawSemesters) {
      for (final result in semester.results) {
        if (excludedIds.contains(result.id)) continue;
        final letter = result.grade.trim().toUpperCase();
        unitsByLetter[letter] = (unitsByLetter[letter] ?? 0) + result.creditUnit;
      }
    }

    if (unitsByLetter.isEmpty) return const SizedBox.shrink();

    final letters = unitsByLetter.entries.map((e) => _LetterTotal(e.key, e.value)).toList()
      ..sort((a, b) => _bucketFor(a.letter).index.compareTo(_bucketFor(b.letter).index));

    final unitsByBucket = <_GradeBucket, int>{};
    for (final l in letters) {
      final bucket = _bucketFor(l.letter);
      unitsByBucket[bucket] = (unitsByBucket[bucket] ?? 0) + l.units;
    }
    final totalUnits = unitsByBucket.values.fold<int>(0, (a, b) => a + b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where your credits sit',
            style: TextStyle(
              color: context.palette.bodyText,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  for (final entry in unitsByBucket.entries)
                    if (totalUnits > 0)
                      Expanded(
                        flex: entry.value,
                        child: ColoredBox(color: entry.key.colorFor(context.palette)),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (final l in letters)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _bucketFor(l.letter).colorFor(context.palette),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${l.units} units at ${l.letter}',
                      style: TextStyle(color: context.palette.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Next-action card — decides FOR the student rather than handing them a
/// list. Priority order (highest first):
///   1. A semester before their current level is missing from the record.
///   2. No goal is set yet.
///   3. Fewer than two semesters exist (no trend yet).
///   4. Otherwise, prompt for the next semester in sequence.
/// Every message is derived from real state — never a generic placeholder.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/engine/projection_solver.dart';
import '../../../domain/models/backfill_plan.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';
import '../../../domain/models/student_profile.dart';

String _phrase(GradingScheme scheme, int level, SemesterTerm term) =>
    '${level}L ${scheme.termLabel(term)}';

({int level, SemesterTerm term}) _nextSemester(int level, SemesterTerm term) {
  if (term == SemesterTerm.first) return (level: level, term: SemesterTerm.second);
  return (level: level + 100, term: SemesterTerm.first);
}

class _NextAction {
  final IconData icon;
  final String text;

  const _NextAction({required this.icon, required this.text});
}

/// Pure priority resolution — public so it can be tested directly without
/// standing up a widget tree.
_NextAction resolveNextAction({
  required AcademicStanding standing,
  required List<Semester> rawSemesters,
  required GradingScheme scheme,
  required StudentProfile? profile,
  required TargetProjection? goal,
}) {
  if (profile != null) {
    final expected = expectedSemesterKeys(
      currentLevel: profile.currentLevel,
      existingSemesters: rawSemesters,
    );
    final missing = expected
        .where((key) => !rawSemesters.any((s) => s.level == key.level && s.term == key.term))
        .toList();
    if (missing.isNotEmpty) {
      missing.sort((a, b) => (a.level * 10 + a.term.index).compareTo(b.level * 10 + b.term.index));
      final earliest = missing.first;
      return _NextAction(
        icon: Icons.add_chart,
        text: 'Add your ${_phrase(scheme, earliest.level, earliest.term)} results',
      );
    }
  }

  if (goal == null) {
    return const _NextAction(icon: Icons.flag_outlined, text: 'Set your target classification');
  }

  if (standing.semesters.length < 2) {
    return const _NextAction(
      icon: Icons.timeline,
      text: 'Add another semester to unlock your trend',
    );
  }

  final latest = rawSemesters.reduce((a, b) => a.sortKey > b.sortKey ? a : b);
  final next = _nextSemester(latest.level, latest.term);
  return _NextAction(
    icon: Icons.add_chart,
    text: 'Add ${_phrase(scheme, next.level, next.term)} results',
  );
}

class NextActionCard extends StatelessWidget {
  final AcademicStanding standing;
  final List<Semester> rawSemesters;
  final GradingScheme scheme;
  final StudentProfile? profile;
  final TargetProjection? goal;
  final VoidCallback onTap;

  const NextActionCard({
    super.key,
    required this.standing,
    required this.rawSemesters,
    required this.scheme,
    required this.profile,
    required this.goal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final action = resolveNextAction(
      standing: standing,
      rawSemesters: rawSemesters,
      scheme: scheme,
      profile: profile,
      goal: goal,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.palette.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action.icon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Next action',
                        style: TextStyle(
                          color: OnboardingLightPalette.secondaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        action.text,
                        style: const TextStyle(
                          color: OnboardingLightPalette.bodyText,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 22, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

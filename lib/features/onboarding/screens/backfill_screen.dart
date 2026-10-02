/// Backfill — Act 2 step 3 of 4. Optional, resumable, never a hard gate.
///
/// The expected semester set is derived from the profile
/// (`domain/models/backfill_plan.dart`), never a fixed 100-600 range — a
/// 300L student has sat four semesters, not six levels' worth, and must
/// never be shown 400L/500L/600L rows for semesters that haven't happened.
///
/// Writes straight to `academicRecordProvider` (persistent Drift), not
/// `onboardingDraftProvider` (session-only) — this screen is reached
/// post-account, so progress must survive closing the app.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/seed/nigerian_institutions.dart';
import '../../../domain/models/backfill_plan.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';
import '../../../shared/widgets/onboarding_header.dart';
import '../../auth/providers/profile_provider.dart';

const _uuid = Uuid();

class BackfillScreen extends ConsumerStatefulWidget {
  const BackfillScreen({super.key});

  @override
  ConsumerState<BackfillScreen> createState() => _BackfillScreenState();
}

class _BackfillScreenState extends ConsumerState<BackfillScreen> {
  bool _checkedSkip = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSkip());
  }

  /// "If the expected count equals the added count ON ENTRY, skip this
  /// screen entirely" — an entry-time check only. Hitting 100% mid-screen
  /// is handled by the ALL ADDED success row instead, not an auto-navigate.
  void _maybeSkip() {
    if (_checkedSkip || !mounted) return;
    _checkedSkip = true;

    final profile = ref.read(studentProfileProvider);
    final record = ref.read(academicRecordProvider);
    final currentLevel = profile?.currentLevel ?? AppConstants.levels.first;
    final expected = expectedSemesterKeys(
      currentLevel: currentLevel,
      existingSemesters: record.semesters,
    );
    final added = countAdded(expected, record.semesters);

    if (added == expected.length) {
      context.go(Routes.goalSetting);
    }
  }

  Institution? _institutionFor(String institutionId) =>
      nigerianInstitutions.where((i) => i.id == institutionId).firstOrNull;

  Future<void> _openSheet({
    required int level,
    required SemesterTerm term,
    required GradingScheme scheme,
    required String levelNoun,
    Semester? existing,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: OnboardingLightPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Theme(
        data: AppTheme.onboardingLight,
        child: _BackfillSemesterSheet(
          level: level,
          term: term,
          levelNoun: levelNoun,
          scheme: scheme,
          existing: existing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(studentProfileProvider);
    final record = ref.watch(academicRecordProvider);
    final currentLevel = profile?.currentLevel ?? AppConstants.levels.first;
    final institution = _institutionFor(record.scheme.institutionId);
    final levelNoun = institution?.levelNoun ?? 'Level';

    final expected = expectedSemesterKeys(
      currentLevel: currentLevel,
      existingSemesters: record.semesters,
    );
    final added = countAdded(expected, record.semesters);
    final allAdded = added == expected.length;
    final fraction = expected.isEmpty ? 0.0 : added / expected.length;

    return Theme(
      data: AppTheme.onboardingLight,
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: colorScheme.surface,
              resizeToAvoidBottomInset: true,
              body: SafeArea(
                child: Column(
                  children: [
                    OnboardingHeader(
                      stepNumber: AccountSetupStep.backfill.stepNumber,
                      totalSteps: AccountSetupStep.totalSteps,
                      title: 'Add Past Semesters',
                      onBack: () => context.go(Routes.profileSetup),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: _BackfillCard(
                          expected: expected,
                          added: added,
                          fraction: fraction,
                          levelNoun: levelNoun,
                          scheme: record.scheme,
                          existingSemesters: record.semesters,
                          onTapSlot: (level, term, existing) => _openSheet(
                            level: level,
                            term: term,
                            scheme: record.scheme,
                            levelNoun: levelNoun,
                            existing: existing,
                          ),
                        ),
                      ),
                    ),
                    _BackfillFooter(
                      added: added,
                      totalExisting: record.semesters.length,
                      allAdded: allAdded,
                      onContinue: () => context.go(Routes.goalSetting),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _BackfillCard extends StatelessWidget {
  final List<SemesterKey> expected;
  final int added;
  final double fraction;
  final String levelNoun;
  final GradingScheme scheme;
  final List<Semester> existingSemesters;
  final void Function(int level, SemesterTerm term, Semester? existing) onTapSlot;

  const _BackfillCard({
    required this.expected,
    required this.added,
    required this.fraction,
    required this.levelNoun,
    required this.scheme,
    required this.existingSemesters,
    required this.onTapSlot,
  });

  Semester? _semesterFor(int level, SemesterTerm term) => existingSemesters
      .where((s) => s.level == level && s.term == term)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final byLevel = <int, List<SemesterKey>>{};
    for (final key in expected) {
      byLevel.putIfAbsent(key.level, () => []).add(key);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(
          color: OnboardingLightPalette.searchBorder,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add your previous semesters',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your CGPA and trend need your full record. You can add these '
            'later from Academics.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: OnboardingLightPalette.secondaryText,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: OnboardingLightPalette.secondaryText,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              children: [
                TextSpan(
                  text: '$added',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' of ${expected.length} semesters added'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _ProgressBar(fraction: fraction),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OnboardingLightPalette.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final level in byLevel.keys) ...[
                  _LevelHeader(
                    level: level,
                    levelNoun: levelNoun,
                    allAdded: byLevel[level]!.every(
                      (k) => _semesterFor(k.level, k.term) != null,
                    ),
                  ),
                  for (var i = 0; i < byLevel[level]!.length; i++) ...[
                    if (i > 0)
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: OnboardingLightPalette.divider,
                        ),
                      ),
                    _SemesterRow(
                      level: byLevel[level]![i].level,
                      term: byLevel[level]![i].term,
                      termLabel: scheme.termLabel(byLevel[level]![i].term),
                      existing: _semesterFor(
                        byLevel[level]![i].level,
                        byLevel[level]![i].term,
                      ),
                      onTap: () => onTapSlot(
                        byLevel[level]![i].level,
                        byLevel[level]![i].term,
                        _semesterFor(
                          byLevel[level]![i].level,
                          byLevel[level]![i].term,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double fraction;
  const _ProgressBar({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                const ColoredBox(color: OnboardingLightPalette.divider),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  width: constraints.maxWidth * fraction.clamp(0, 1),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        OnboardingLightPalette.primaryGradientStart,
                        OnboardingLightPalette.primary,
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  final int level;
  final String levelNoun;
  final bool allAdded;

  const _LevelHeader({
    required this.level,
    required this.levelNoun,
    required this.allAdded,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: allAdded
          ? OnboardingLightPalette.success.withValues(alpha: 0.06)
          : Colors.white,
      child: Text(
        '$level $levelNoun',
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SemesterRow extends StatelessWidget {
  final int level;
  final SemesterTerm term;
  final String termLabel;
  final Semester? existing;
  final VoidCallback onTap;

  const _SemesterRow({
    required this.level,
    required this.term,
    required this.termLabel,
    required this.existing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final added = existing != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 62,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    termLabel,
                    style: const TextStyle(
                      color: OnboardingLightPalette.bodyText,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: added
                      ? const Row(
                          key: ValueKey('added'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 20,
                              color: OnboardingLightPalette.success,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Added',
                              style: TextStyle(
                                color: OnboardingLightPalette.success,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          key: const ValueKey('missing'),
                          height: 44,
                          child: Center(
                            child: Text(
                              'Add',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackfillFooter extends StatelessWidget {
  final int added;
  final int totalExisting;
  final bool allAdded;
  final VoidCallback onContinue;

  const _BackfillFooter({
    required this.added,
    required this.totalExisting,
    required this.allAdded,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showTrendInfo = totalExisting < 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (allAdded) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: OnboardingLightPalette.success,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Your full record is in',
                    style: TextStyle(
                      color: OnboardingLightPalette.success,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _PrimaryFooterButton(
              label: 'Continue',
              gradient: true,
              onPressed: onContinue,
            ),
          ] else if (added > 0) ...[
            _PrimaryFooterButton(
              label: 'Continue',
              gradient: true,
              onPressed: onContinue,
            ),
          ] else ...[
            _PrimaryFooterButton(
              label: "I'll do this later",
              gradient: false,
              onPressed: onContinue,
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'You can add past semesters any time from Academics.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: OnboardingLightPalette.secondaryText,
              fontSize: 14.5,
            ),
          ),
          if (showTrendInfo) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.trending_up, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'With two or more semesters we can show your CGPA '
                      'trend and tell you what you need for your target.',
                      style: TextStyle(
                        color: OnboardingLightPalette.bodyText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryFooterButton extends StatefulWidget {
  final String label;
  final bool gradient;
  final VoidCallback onPressed;

  const _PrimaryFooterButton({
    required this.label,
    required this.gradient,
    required this.onPressed,
  });

  @override
  State<_PrimaryFooterButton> createState() => _PrimaryFooterButtonState();
}

class _PrimaryFooterButtonState extends State<_PrimaryFooterButton> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!widget.gradient) {
      return GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressed
                ? colorScheme.primary.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed
                  ? colorScheme.primary
                  : OnboardingLightPalette.searchBorder,
              width: 1.2,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      key: const ValueKey('backfillContinueTap'),
      onTap: widget.onPressed,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: !_pressed
              ? const LinearGradient(
                  colors: [
                    OnboardingLightPalette.primaryGradientStart,
                    OnboardingLightPalette.primary,
                  ],
                )
              : null,
          color: _pressed ? OnboardingLightPalette.primary : null,
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: OnboardingLightPalette.primary.withValues(alpha: 0.22),
                    blurRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: OnboardingLightPalette.primary.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: OnboardingLightPalette.primary.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Course code + credit + grade entry for one (level, term) slot, with the
/// slot itself locked — reusing the Act 1 course/grade entry shape, but as
/// a single-step sheet since level and term are already known here. Not
/// shared with `add_semester_sheet.dart` (Academics' own editable-level
/// sheet, dark-themed) — the two have different enough constraints
/// (locked vs freely-chosen level/term, light vs dark) that sharing one
/// widget would mean threading conditionals through both call sites.
class _BackfillSemesterSheet extends ConsumerStatefulWidget {
  final int level;
  final SemesterTerm term;
  final String levelNoun;
  final GradingScheme scheme;
  final Semester? existing;

  const _BackfillSemesterSheet({
    required this.level,
    required this.term,
    required this.levelNoun,
    required this.scheme,
    this.existing,
  });

  @override
  ConsumerState<_BackfillSemesterSheet> createState() =>
      _BackfillSemesterSheetState();
}

class _DraftRow {
  final String courseCode;
  final int? creditUnit;
  final String? grade;

  const _DraftRow({this.courseCode = '', this.creditUnit, this.grade});

  bool get isComplete =>
      courseCode.trim().isNotEmpty && creditUnit != null && grade != null;

  _DraftRow copyWith({String? courseCode, int? creditUnit, String? grade}) =>
      _DraftRow(
        courseCode: courseCode ?? this.courseCode,
        creditUnit: creditUnit ?? this.creditUnit,
        grade: grade ?? this.grade,
      );
}

class _BackfillSemesterSheetState
    extends ConsumerState<_BackfillSemesterSheet> {
  late final TextEditingController _sessionController =
      TextEditingController(text: widget.existing?.session ?? _estimateSession());
  late List<_DraftRow> _rows = widget.existing != null
      ? widget.existing!.results
          .map((r) => _DraftRow(
                courseCode: r.courseCode,
                creditUnit: r.creditUnit,
                grade: r.grade,
              ))
          .toList()
      : const [_DraftRow()];

  bool get _isEditing => widget.existing != null;

  String _estimateSession() {
    final now = DateTime.now();
    final currentSessionStartYear = now.month >= 9 ? now.year : now.year - 1;
    // Each level below the "current" one (assumed the most recent session)
    // is roughly one academic year earlier.
    final levelsAgo = ((AppConstants.levels.last - widget.level) / 100).round();
    final startYear = currentSessionStartYear - levelsAgo;
    return '$startYear/${startYear + 1}';
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  bool get _canSave => _rows.any((r) => r.isComplete);

  void _save() {
    final now = DateTime.now();
    final semesterId = widget.existing?.id ?? _uuid.v4();
    final results = _rows.where((r) => r.isComplete).map((r) {
      return CourseResult(
        id: _uuid.v4(),
        semesterId: semesterId,
        courseCode: r.courseCode.trim().toUpperCase(),
        creditUnit: r.creditUnit!,
        grade: r.grade!,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    final semester = Semester(
      id: semesterId,
      profileId: widget.existing?.profileId ?? AppConstants.localProfileId,
      session: _sessionController.text.trim(),
      term: widget.term,
      level: widget.level,
      results: results,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(academicRecordProvider.notifier);
    if (_isEditing) {
      notifier.updateSemester(semester);
    } else {
      notifier.addSemester(semester);
    }
    Navigator.of(context).pop();
  }

  Future<void> _confirmRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this semester?'),
        content: Text(
          'This deletes all ${_rows.length} course result(s) for '
          '${widget.level} ${widget.levelNoun} — ${widget.scheme.termLabel(widget.term)}. '
          'Your CGPA will be recalculated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: OnboardingLightPalette.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref.read(academicRecordProvider.notifier).removeSemester(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.level} ${widget.levelNoun} — '
              '${widget.scheme.termLabel(widget.term)}',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sessionController,
              decoration: InputDecoration(
                labelText: 'Session',
                hintText: 'e.g. 2022/2023',
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: OnboardingLightPalette.searchBorder),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _rows.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  if (i == _rows.length) {
                    return OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _rows = [..._rows, const _DraftRow()]),
                      icon: const Icon(Icons.add_outlined),
                      label: const Text('Add another course'),
                    );
                  }
                  return _BackfillRowEditor(
                    row: _rows[i],
                    scheme: widget.scheme,
                    onChanged: (r) => setState(() {
                      final next = [..._rows];
                      next[i] = r;
                      _rows = next;
                    }),
                    onRemove: _rows.length > 1
                        ? () => setState(() {
                              final next = [..._rows]..removeAt(i);
                              _rows = next;
                            })
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (_isEditing) ...[
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _confirmRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: OnboardingLightPalette.error,
                  ),
                  child: const Text('Remove this semester'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            _PrimaryFooterButton(
              label: _isEditing ? 'Save changes' : 'Save semester',
              gradient: _canSave,
              onPressed: _canSave ? _save : () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _BackfillRowEditor extends StatelessWidget {
  final _DraftRow row;
  final GradingScheme scheme;
  final ValueChanged<_DraftRow> onChanged;
  final VoidCallback? onRemove;

  const _BackfillRowEditor({
    required this.row,
    required this.scheme,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: OnboardingLightPalette.searchBorder, width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: row.courseCode,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Course',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => onChanged(row.copyWith(courseCode: v)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              initialValue: row.creditUnit,
              decoration: const InputDecoration(
                labelText: 'Units',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                AppConstants.maxCreditUnit,
                (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
              ),
              onChanged: (v) => onChanged(row.copyWith(creditUnit: v)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: row.grade,
              decoration: const InputDecoration(
                labelText: 'Grade',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: scheme.grades
                  .map((g) => DropdownMenuItem(value: g.letter, child: Text(g.letter)))
                  .toList(),
              onChanged: (v) => onChanged(row.copyWith(grade: v)),
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close_outlined, size: 18),
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
        ],
      ),
    );
  }
}

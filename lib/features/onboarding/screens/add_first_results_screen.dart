/// Add first results — the single most important screen in the app.
///
/// A 400-level student has roughly 40 courses behind them. If onboarding
/// demands 40 rows of typing before any value appears, most users abandon
/// around course six. This is where every Nigerian CGPA app has died.
///
/// Three steps: optionally photograph the course registration slip (kept
/// as a visual reference only — see [_SlipStep]), list your courses (code +
/// credit unit), then fill in one grade per course. No OCR — there is no
/// extraction service wired up, and AGENTS.md is explicit that a
/// fabricated grade is worse than none. Splitting course entry from grade
/// entry still turns "type everything in one long form" into "list what
/// you took, then just fill in the blanks," which is the shape that
/// matters even without automatic extraction.
///
/// NOTE: we deliberately do NOT offer portal-credential scraping. Asking a
/// student for their university login is a credential-theft liability, it
/// breaks on every portal redesign, and it likely violates the institution's
/// terms of use.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../providers/onboarding_provider.dart';

enum _Step { slip, courses, grades }

class AddFirstResultsScreen extends ConsumerStatefulWidget {
  const AddFirstResultsScreen({super.key});

  @override
  ConsumerState<AddFirstResultsScreen> createState() =>
      _AddFirstResultsScreenState();
}

class _AddFirstResultsScreenState extends ConsumerState<AddFirstResultsScreen> {
  _Step _step = _Step.slip;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);

    final validRows = draft.rows
        .where((r) => r.courseCode.trim().isNotEmpty && r.creditUnit != null)
        .toList();
    final coursesReady = validRows.isNotEmpty;
    final allGraded = coursesReady && validRows.every((r) => r.grade != null);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Add your results'),
        automaticallyImplyLeading: _step != _Step.slip,
        leading: _step == _Step.slip
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _step = _step == _Step.grades ? _Step.courses : _Step.slip;
                }),
              ),
      ),
      body: SafeArea(
        child: switch (_step) {
          _Step.slip => _SlipStep(onContinue: () => setState(() => _step = _Step.courses)),
          _Step.courses => _CoursesStep(
              draft: draft,
              notifier: notifier,
              canContinue: coursesReady,
              onContinue: () => setState(() => _step = _Step.grades),
            ),
          _Step.grades => _GradesStep(
              rows: validRows,
              draft: draft,
              notifier: notifier,
              canSave: allGraded,
              onSave: () {
                notifier.commitDraft();
                context.go(Routes.gpaReveal);
              },
            ),
        },
      ),
    );
  }
}

/// Step 1 — optional photo of the course registration slip. Kept as a
/// visual reference only; nothing reads it. The card is a slightly
/// unequal stack, not a single flat rectangle.
class _SlipStep extends StatefulWidget {
  final VoidCallback onContinue;

  const _SlipStep({required this.onContinue});

  @override
  State<_SlipStep> createState() => _SlipStepState();
}

class _SlipStepState extends State<_SlipStep> {
  final _picker = ImagePicker();
  Uint8List? _pickedBytes;
  bool _picking = false;

  Future<void> _pick(ImageSource source) async {
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _pickedBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Could not open the camera on this device.'
                : 'Could not open the file picker.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picked = _pickedBytes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: picked == null
                  ? _StackedUploadCard(picking: _picking)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.memory(picked, width: double.infinity, height: 280, fit: BoxFit.cover),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                tooltip: 'Remove photo',
                                onPressed: () => setState(() => _pickedBytes = null),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          if (picked == null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose file'),
                    onPressed: _picking ? null : () => _pick(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take photo'),
                    onPressed: _picking ? null : () => _pick(ImageSource.camera),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Text(
            picked == null
                ? 'Everything stays on your device until you choose to save it.'
                : 'Saved as a reference — you\'ll list your courses next.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              onPressed: widget.onContinue,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dropzone card, drawn as a stack of unequally-offset cards rather
/// than one flat rectangle.
class _StackedUploadCard extends StatelessWidget {
  final bool picking;

  const _StackedUploadCard({required this.picking});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 18,
            left: 6,
            right: 26,
            bottom: 6,
            child: Transform.rotate(
              angle: -0.09,
              child: GlassCard(
                blurSigma: 6,
                borderRadius: BorderRadius.circular(20),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 20,
            right: 6,
            bottom: 22,
            child: Transform.rotate(
              angle: 0.06,
              child: GlassCard(
                blurSigma: 10,
                borderRadius: BorderRadius.circular(20),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          GlassCard(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  child: picking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.camera_alt_outlined, size: 28, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upload or photograph your course registration slip',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ll keep it here while you add your results below',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 2 — list courses (code + credit unit only, no grade yet).
class _CoursesStep extends StatelessWidget {
  final OnboardingDraft draft;
  final OnboardingDraftNotifier notifier;
  final bool canContinue;
  final VoidCallback onContinue;

  const _CoursesStep({
    required this.draft,
    required this.notifier,
    required this.canContinue,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _SessionSelector(
            session: draft.session,
            level: draft.level,
            term: draft.term,
            onChanged: notifier.setSemesterContext,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'What courses did you take?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: draft.rows.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              if (i == draft.rows.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton.icon(
                    onPressed: notifier.addBlankRow,
                    icon: const Icon(Icons.add),
                    label: const Text('Add another course'),
                  ),
                );
              }
              return _CourseRow(
                row: draft.rows[i],
                onChanged: (r) => notifier.updateRow(i, r),
                onRemove: draft.rows.length > 1 ? () => notifier.removeRow(i) : null,
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: canContinue ? onContinue : null,
                child: const Text('Next: Add your grades'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CourseRow extends StatelessWidget {
  final DraftResultRow row;
  final ValueChanged<DraftResultRow> onChanged;
  final VoidCallback? onRemove;

  const _CourseRow({required this.row, required this.onChanged, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: row.courseCode,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Course', isDense: true),
              onChanged: (v) => onChanged(row.copyWith(courseCode: v)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              initialValue: row.creditUnit,
              decoration: const InputDecoration(labelText: 'Units', isDense: true),
              items: List.generate(
                AppConstants.maxCreditUnit,
                (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
              ),
              onChanged: (v) => onChanged(row.copyWith(creditUnit: v)),
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
        ],
      ),
    );
  }
}

/// Step 3 — the same course list, one grade field each.
class _GradesStep extends StatelessWidget {
  final List<DraftResultRow> rows;
  final OnboardingDraft draft;
  final OnboardingDraftNotifier notifier;
  final bool canSave;
  final VoidCallback onSave;

  const _GradesStep({
    required this.rows,
    required this.draft,
    required this.notifier,
    required this.canSave,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Fill in your grades',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final row = rows[i];
              final index = draft.rows.indexOf(row);
              return _GradeRow(
                row: row,
                scheme: draft.scheme,
                onChanged: (r) => notifier.updateRow(index, r),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: canSave ? onSave : null,
                child: const Text('Calculate my GPA'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradeRow extends StatelessWidget {
  final DraftResultRow row;
  final GradingScheme scheme;
  final ValueChanged<DraftResultRow> onChanged;

  const _GradeRow({required this.row, required this.scheme, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.courseCode, style: theme.textTheme.titleSmall),
                Text(
                  '${row.creditUnit} unit${row.creditUnit == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: row.grade,
              decoration: const InputDecoration(labelText: 'Grade', isDense: true),
              items: scheme.grades
                  .map((g) => DropdownMenuItem(
                        value: g.letter,
                        child: Text('${g.letter} (${g.point})'),
                      ))
                  .toList(),
              onChanged: (v) => onChanged(row.copyWith(grade: v)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionSelector extends StatelessWidget {
  final String session;
  final int level;
  final SemesterTerm term;
  final void Function({String? session, int? level, SemesterTerm? term})
      onChanged;

  const _SessionSelector({
    required this.session,
    required this.level,
    required this.term,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: level,
              decoration: const InputDecoration(labelText: 'Level'),
              items: AppConstants.levels
                  .map((l) =>
                      DropdownMenuItem(value: l, child: Text('$l Level')))
                  .toList(),
              onChanged: (v) => onChanged(level: v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<SemesterTerm>(
              initialValue: term,
              decoration: const InputDecoration(labelText: 'Semester'),
              items: SemesterTerm.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.shortLabel)))
                  .toList(),
              onChanged: (v) => onChanged(term: v),
            ),
          ),
        ],
      );
}

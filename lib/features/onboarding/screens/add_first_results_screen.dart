/// Add first results — the single most important screen in the app.
///
/// A 400-level student has roughly 40 courses behind them. If onboarding
/// demands 40 rows of typing before any value appears, most users abandon
/// around course six. This is where every Nigerian CGPA app has died.
///
/// The import path (photograph a result slip -> OCR -> editable review
/// table) turns twenty minutes of typing into thirty seconds and one review
/// pass. Manual entry stays as the always-available fallback.
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
import '../providers/onboarding_provider.dart';
import '../widgets/result_entry_row.dart';

class AddFirstResultsScreen extends ConsumerStatefulWidget {
  const AddFirstResultsScreen({super.key});

  @override
  ConsumerState<AddFirstResultsScreen> createState() =>
      _AddFirstResultsScreenState();
}

class _AddFirstResultsScreenState extends ConsumerState<AddFirstResultsScreen> {
  bool _importMode = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);

    final canContinue = draft.rows.any((r) => r.isComplete);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add your results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.goalSetting),
        ),
      ),
      body: SafeArea(
        child: Column(
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
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Import slip'),
                    icon: Icon(Icons.photo_camera_outlined),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Manual entry'),
                    icon: Icon(Icons.edit_outlined),
                  ),
                ],
                selected: {_importMode},
                onSelectionChanged: (s) =>
                    setState(() => _importMode = s.first),
              ),
            ),
            Expanded(
              child: _importMode
                  ? _ImportPane(
                      onContinueToManual: () => setState(() => _importMode = false),
                    )
                  : _ManualPane(
                      rows: draft.rows,
                      onChanged: notifier.updateRow,
                      onRemove: notifier.removeRow,
                      onAdd: notifier.addBlankRow,
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (draft.hasFlaggedRows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 18, color: theme.colorScheme.tertiary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${draft.flaggedCount} row(s) need a quick '
                                'check before we count them.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: canContinue
                            ? () {
                                notifier.commitDraft();
                                context.go(Routes.gpaReveal);
                              }
                            : null,
                        child: const Text('Calculate my GPA'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

/// Import pane.
///
/// Picking a photo is real — [ImagePicker] actually opens the gallery or
/// camera and the slip is kept as a visual reference. TODO(v1): wire the
/// picked image to an OCR service so the review table below pre-fills
/// itself. Before planning around that, grab a real result slip from the
/// target institution and test extraction on it — if accuracy is poor on
/// the actual portal output format, the whole screen collapses back into
/// manual typing and the flow needs rethinking. Until then, a picked photo
/// hands off to manual entry rather than inventing grades no OCR pass ever
/// actually read — a fabricated grade is worse than none.
class _ImportPane extends StatefulWidget {
  final VoidCallback onContinueToManual;

  const _ImportPane({required this.onContinueToManual});

  @override
  State<_ImportPane> createState() => _ImportPaneState();
}

class _ImportPaneState extends State<_ImportPane> {
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (picked == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: _picking
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.camera_alt_outlined,
                              size: 28,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Upload or photograph your result slip',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We\'ll keep it here while you add your results below',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.memory(
                      picked,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
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
            const SizedBox(height: 16),
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
                    child: FilledButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take photo'),
                      onPressed: _picking ? null : () => _pick(ImageSource.camera),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.checklist_outlined),
                  label: const Text('Enter what\'s on the slip'),
                  onPressed: widget.onContinueToManual,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              picked == null
                  ? 'Everything stays on your device until you choose to save it.'
                  : 'Automatic reading isn\'t available yet — add the courses you see in the photo below.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualPane extends StatelessWidget {
  final List<DraftResultRow> rows;
  final void Function(int, DraftResultRow) onChanged;
  final void Function(int) onRemove;
  final VoidCallback onAdd;

  const _ManualPane({
    required this.rows,
    required this.onChanged,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: rows.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i == rows.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add another course'),
              ),
            );
          }
          return ResultEntryRow(
            row: rows[i],
            onChanged: (r) => onChanged(i, r),
            onRemove: rows.length > 1 ? () => onRemove(i) : null,
          );
        },
      );
}

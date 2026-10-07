/// Shared "add a semester" flow for Academics/Results. Commits straight to
/// [academicRecordProvider] — kept independent from [onboardingDraftProvider]'s
/// commit path, which still owns the Add Results/GPA reveal flow and has
/// different "who owns this state" semantics.
///
/// ⚠ FIXED: this sheet used to wrap itself in `GlassCard` — a frosted
/// translucent fill with white text, built for the app's old permanent
/// dark gradient background. Every other screen that hit this same bug
/// (`results_view.dart`/`roadmap_view.dart`/`reports_view.dart`) was already
/// rebuilt onto a solid, theme-aware surface; this sheet hadn't been, which
/// is why its text read as low-contrast/"dark" sitting over the light modal
/// scrim. Now a solid white sheet with explicit `context.palette` colours
/// throughout, matching `_SemesterDetailSheet`'s look below.
///
/// "Scan registration slip" drafts rows from a photo via the
/// `extract-course-slip` Edge Function -- course code/title/unit only,
/// never a grade (a registration slip is filled out before results exist).
/// Extracted rows below the confidence threshold are flagged so the student
/// double-checks them before saving, the same convention as
/// `CourseResult.needsReview`.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';
import '../services/course_slip_extraction_service.dart';
import '../services/result_slip_ocr_service.dart';

const _uuid = Uuid();

InputDecoration _fieldDecoration(BuildContext context, String label, {bool dense = false}) {
  final palette = context.palette;
  return InputDecoration(
    labelText: label,
    isDense: dense,
    filled: true,
    fillColor: palette.background,
    labelStyle: TextStyle(color: palette.secondaryText),
    floatingLabelStyle: TextStyle(color: palette.primary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: palette.surfaceBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: palette.surfaceBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: palette.primary, width: 1.6),
    ),
  );
}

class _DraftRow {
  /// Stable across edits (`copyWith` always carries it forward) — used as
  /// the `_RowEditor`'s key so its `TextFormField`s keep their own state
  /// (cursor position, etc.) while a student is typing, but a genuinely new
  /// row (a fresh manual row, or one replaced wholesale by a slip scan)
  /// gets a fresh widget seeded with its own `initialValue` instead of
  /// silently reusing stale on-screen text from whatever used to sit at
  /// that list index.
  final String id;

  final String courseCode;
  final String courseTitle;
  final int? creditUnit;
  final String? grade;
  final ResultSource source;
  final double? extractionConfidence;

  _DraftRow({
    String? id,
    this.courseCode = '',
    this.courseTitle = '',
    this.creditUnit,
    this.grade,
    this.source = ResultSource.manual,
    this.extractionConfidence,
  }) : id = id ?? _uuid.v4();

  factory _DraftRow.fromExtracted(ExtractedCourse c) => _DraftRow(
        courseCode: c.courseCode,
        courseTitle: c.courseTitle ?? '',
        creditUnit: c.creditUnit,
        source: ResultSource.ocrImport,
        extractionConfidence: c.confidence,
      );

  /// From the on-device result-slip scanner -- unlike [fromExtracted], this
  /// may carry a guessed grade, since that's what makes a result slip a
  /// result slip. [scheme] gates it: `_RowEditor`'s grade field is a
  /// `DropdownButtonFormField` whose items are exactly `scheme.grades`, and
  /// Flutter asserts if `initialValue` isn't one of them (see AGENTS.md's
  /// "Things not to do" on this exact dropdown-assertion bug) -- an OCR
  /// misread like "AB" or a stray letter must fall back to no pre-fill
  /// (the student picks from the dropdown themselves) rather than crash
  /// the sheet.
  factory _DraftRow.fromOcrResultLine(ExtractedResultLine r, GradingScheme scheme) => _DraftRow(
        courseCode: r.courseCode,
        courseTitle: r.courseTitle ?? '',
        creditUnit: r.creditUnit != null && r.creditUnit! >= 1 && r.creditUnit! <= AppConstants.maxCreditUnit
            ? r.creditUnit
            : null,
        grade: scheme.grades.any((g) => g.letter == r.grade) ? r.grade : null,
        source: ResultSource.ocrImport,
        extractionConfidence: r.confidence,
      );

  factory _DraftRow.fromResult(CourseResult r) => _DraftRow(
        courseCode: r.courseCode,
        courseTitle: r.courseTitle ?? '',
        creditUnit: r.creditUnit,
        grade: r.grade,
        source: r.source,
        extractionConfidence: r.extractionConfidence,
      );

  bool get isComplete =>
      courseCode.trim().isNotEmpty && creditUnit != null && grade != null;

  bool get needsReview =>
      extractionConfidence != null && extractionConfidence! < 0.85;

  bool get hasAnyInput =>
      courseCode.trim().isNotEmpty || courseTitle.trim().isNotEmpty || creditUnit != null || grade != null;

  _DraftRow copyWith({String? courseCode, String? courseTitle, int? creditUnit, String? grade}) =>
      _DraftRow(
        id: id,
        courseCode: courseCode ?? this.courseCode,
        courseTitle: courseTitle ?? this.courseTitle,
        creditUnit: creditUnit ?? this.creditUnit,
        grade: grade ?? this.grade,
        source: source,
        extractionConfidence: extractionConfidence,
      );
}

/// Whether [level]/[term] is already on record -- the key a re-upload of
/// the "same" semester collides on. Session text is deliberately NOT part
/// of the match: a typo'd or reformatted session string ("2023/2024" vs
/// "2023-2024") must never let a genuine duplicate slip through.
Semester? _existingSemesterFor(List<Semester> semesters, int level, SemesterTerm term) =>
    semesters.cast<Semester?>().firstWhere(
          (s) => s!.level == level && s.term == term,
          orElse: () => null,
        );

/// Shown when [showAddSemesterSheet] is about to save a (level, term) pair
/// that's already on record. `onEditExisting` is null when there's no
/// reachable "open that semester" action from this call site (there isn't
/// one yet from Backfill) -- the dialog just drops that option rather than
/// offering a dead button.
Future<void> _showDuplicateSemesterAlert(
  BuildContext context, {
  required int level,
  required SemesterTerm term,
  required VoidCallback? onEditExisting,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.info_outline, color: context.palette.amber, size: 28),
      title: const Text('Already uploaded'),
      content: Text(
        '$level Level ${term.shortLabel} Semester is already on your record. '
        'Move on to your next semester, or edit this one instead if a '
        'carryover course needs correcting.',
      ),
      actions: [
        if (onEditExisting != null)
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onEditExisting();
            },
            child: const Text('Edit existing'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> showAddSemesterSheet(
  BuildContext context, {
  int? initialLevel,
  SemesterTerm? initialTerm,
  void Function(String semesterId)? onEditExisting,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddSemesterSheet(
      initialLevel: initialLevel,
      initialTerm: initialTerm,
      onEditExisting: onEditExisting,
    ),
  );
}

class AddSemesterSheet extends ConsumerStatefulWidget {
  final int? initialLevel;
  final SemesterTerm? initialTerm;
  final void Function(String semesterId)? onEditExisting;

  const AddSemesterSheet({super.key, this.initialLevel, this.initialTerm, this.onEditExisting});

  @override
  ConsumerState<AddSemesterSheet> createState() => _AddSemesterSheetState();
}

class _AddSemesterSheetState extends ConsumerState<AddSemesterSheet> {
  late int _level = widget.initialLevel ?? AppConstants.levels.first;
  late SemesterTerm _term = widget.initialTerm ?? SemesterTerm.first;
  late String _session = _currentSession();
  List<_DraftRow> _rows = [_DraftRow()];
  bool _scanning = false;
  String? _scanError;

  static String _currentSession() {
    final y = DateTime.now().year;
    return DateTime.now().month >= 9 ? '$y/${y + 1}' : '${y - 1}/$y';
  }

  static Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  Future<void> _scanSlip() async {
    final palette = context.palette;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: palette.primary),
              title: Text('Take a photo', style: TextStyle(color: palette.bodyText)),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: palette.primary),
              title: Text('Choose from gallery', style: TextStyle(color: palette.bodyText)),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() {
      _scanning = true;
      _scanError = null;
    });

    try {
      final bytes = await pickRegistrationSlipBytes(source);
      if (bytes == null) {
        if (mounted) setState(() => _scanning = false);
        return;
      }

      if (!await _isOnline()) {
        throw const SlipExtractionException(
          "You're offline -- connect to the internet to scan a slip, or enter courses manually.",
        );
      }

      final processed = processRegistrationSlip(bytes);
      final extracted = await extractCoursesFromSlip(processed);
      if (!mounted) return;

      setState(() {
        final draftRows = extracted.map(_DraftRow.fromExtracted).toList();
        // Once a student has typed anything into the existing rows, a scan
        // adds to them rather than silently discarding that typing.
        final hasManualInput = _rows.any((r) => r.hasAnyInput);
        _rows = hasManualInput ? [..._rows, ...draftRows] : draftRows;
        _scanning = false;
      });
    } on SlipExtractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _scanError = e.message;
      });
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _scanError = "That doesn't look like a readable image. Try a different photo.";
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _scanError = 'Something went wrong reading that slip. Try again or enter courses manually.';
      });
    }
  }

  /// On-device counterpart to [_scanSlip] -- a *result* slip (grades
  /// already issued), read by `result_slip_ocr_service.dart`'s offline ML
  /// Kit text recognizer rather than the server-side vision model, so it
  /// works with no connection. See that file's doc comment for why its
  /// output is always lower-confidence and never pre-fills an invalid
  /// grade/unit value.
  Future<void> _scanResultSlip() async {
    final palette = context.palette;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: palette.primary),
              title: Text('Take a photo', style: TextStyle(color: palette.bodyText)),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: palette.primary),
              title: Text('Choose from gallery', style: TextStyle(color: palette.bodyText)),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() {
      _scanning = true;
      _scanError = null;
    });

    try {
      final path = await pickResultSlipImagePath(source);
      if (path == null) {
        if (mounted) setState(() => _scanning = false);
        return;
      }

      final extracted = await extractResultsFromImage(path);
      if (!mounted) return;

      if (extracted.isEmpty) {
        setState(() {
          _scanning = false;
          _scanError = "Couldn't find any course rows on that slip. Try a clearer photo or enter courses manually.";
        });
        return;
      }

      final scheme = ref.read(academicRecordProvider).scheme;
      setState(() {
        final draftRows = extracted.map((r) => _DraftRow.fromOcrResultLine(r, scheme)).toList();
        final hasManualInput = _rows.any((r) => r.hasAnyInput);
        _rows = hasManualInput ? [..._rows, ...draftRows] : draftRows;
        _scanning = false;
      });
    } on ResultSlipOcrException catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _scanError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _scanError = 'Something went wrong reading that slip. Try again or enter courses manually.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = ref.watch(academicRecordProvider).scheme;
    final canSave = _rows.any((r) => r.isComplete);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: palette.divider, borderRadius: BorderRadius.circular(999)),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  Text(
                    'Add a semester',
                    style: TextStyle(color: palette.bodyText, fontSize: 21, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter courses manually or scan your registration slip.',
                    style: TextStyle(color: palette.secondaryText, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _level,
                          dropdownColor: palette.surface,
                          style: TextStyle(color: palette.bodyText, fontSize: 15),
                          decoration: _fieldDecoration(context, 'Level'),
                          items: AppConstants.levels
                              .map((l) => DropdownMenuItem(value: l, child: Text('$l Level')))
                              .toList(),
                          onChanged: (v) => setState(() => _level = v ?? _level),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<SemesterTerm>(
                          initialValue: _term,
                          dropdownColor: palette.surface,
                          style: TextStyle(color: palette.bodyText, fontSize: 15),
                          decoration: _fieldDecoration(context, 'Semester'),
                          items: SemesterTerm.values
                              .map((t) => DropdownMenuItem(value: t, child: Text(t.shortLabel)))
                              .toList(),
                          onChanged: (v) => setState(() => _term = v ?? _term),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _session,
                    style: TextStyle(color: palette.bodyText, fontSize: 15),
                    decoration: _fieldDecoration(context, 'Session, e.g. 2023/2024'),
                    onChanged: (v) => _session = v,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const ValueKey('scanRegistrationSlipTap'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.primary,
                        side: BorderSide(color: palette.primary.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _scanning ? null : _scanSlip,
                      icon: _scanning
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
                            )
                          : const Icon(Icons.document_scanner_outlined),
                      label: Text(_scanning ? 'Reading slip…' : 'Scan registration slip'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const ValueKey('scanResultSlipTap'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.secondaryText,
                        side: BorderSide(color: palette.surfaceBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _scanning ? null : _scanResultSlip,
                      icon: _scanning
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: palette.secondaryText),
                            )
                          : const Icon(Icons.offline_bolt_outlined),
                      label: Text(_scanning ? 'Reading slip…' : 'Scan result slip (offline)'),
                    ),
                  ),
                  if (_scanError != null) ...[
                    const SizedBox(height: 8),
                    Text(_scanError!, key: const ValueKey('scanSlipError'), style: TextStyle(color: palette.error, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  for (var i = 0; i < _rows.length; i++) ...[
                    _RowEditor(
                      key: ValueKey(_rows[i].id),
                      row: _rows[i],
                      scheme: scheme,
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
                    ),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.secondaryText,
                      side: BorderSide(color: palette.surfaceBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setState(() => _rows = [..._rows, _DraftRow()]),
                    icon: const Icon(Icons.add),
                    label: const Text('Add another course'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: canSave ? _save : null,
                      child: const Text('Save semester', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final record = ref.read(academicRecordProvider);
    final existing = _existingSemesterFor(record.semesters, _level, _term);
    if (existing != null) {
      final onEditExisting = widget.onEditExisting;
      await _showDuplicateSemesterAlert(
        context,
        level: _level,
        term: _term,
        onEditExisting: onEditExisting == null
            ? null
            : () {
                if (mounted) Navigator.of(context).pop();
                onEditExisting(existing.id);
              },
      );
      return;
    }

    final now = DateTime.now();
    final semesterId = _uuid.v4();

    final results = _rows.where((r) => r.isComplete).map((r) {
      return CourseResult(
        id: _uuid.v4(),
        semesterId: semesterId,
        courseCode: r.courseCode.trim().toUpperCase(),
        courseTitle: r.courseTitle.trim().isEmpty ? null : r.courseTitle.trim(),
        creditUnit: r.creditUnit!,
        grade: r.grade!,
        source: r.source,
        extractionConfidence: r.extractionConfidence,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    ref.read(academicRecordProvider.notifier).addSemester(
          Semester(
            id: semesterId,
            profileId: AppConstants.localProfileId,
            session: _session,
            term: _term,
            level: _level,
            results: results,
            createdAt: now,
            updatedAt: now,
          ),
        );

    if (mounted) Navigator.of(context).pop();
  }
}

class _RowEditor extends StatelessWidget {
  final _DraftRow row;
  final GradingScheme scheme;
  final ValueChanged<_DraftRow> onChanged;
  final VoidCallback? onRemove;

  const _RowEditor({
    super.key,
    required this.row,
    required this.scheme,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (row.needsReview)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 14, color: palette.amber),
                  const SizedBox(width: 6),
                  Text(
                    'Low-confidence scan -- double-check this row',
                    style: TextStyle(color: palette.amber, fontSize: 12),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: row.courseCode,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(color: palette.bodyText, fontSize: 14.5),
                  decoration: _fieldDecoration(context, 'Course', dense: true),
                  onChanged: (v) => onChanged(row.copyWith(courseCode: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  initialValue: row.creditUnit,
                  dropdownColor: palette.surface,
                  style: TextStyle(color: palette.bodyText, fontSize: 14.5),
                  decoration: _fieldDecoration(context, 'Units', dense: true),
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
                  dropdownColor: palette.surface,
                  style: TextStyle(color: palette.bodyText, fontSize: 14.5),
                  decoration: _fieldDecoration(context, 'Grade', dense: true),
                  items: scheme.grades
                      .map((g) => DropdownMenuItem(value: g.letter, child: Text(g.letter)))
                      .toList(),
                  onChanged: (v) => onChanged(row.copyWith(grade: v)),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: palette.secondaryText),
                  onPressed: onRemove,
                  tooltip: 'Remove',
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: row.courseTitle,
            style: TextStyle(color: palette.bodyText, fontSize: 14.5),
            decoration: _fieldDecoration(context, 'Course title (optional)', dense: true),
            onChanged: (v) => onChanged(row.copyWith(courseTitle: v)),
          ),
        ],
      ),
    );
  }
}

/// Full-row edit for a course already saved to a semester -- course code,
/// credit unit AND grade, not just the grade (`_SemesterDetailSheet` in
/// `results_view.dart` used to offer grade-only editing; a carryover course
/// entered with the wrong code/units had no fix short of delete-and-re-add).
/// Also doubles as "add a course to an already-saved semester" when
/// [initial] is null, for a carryover discovered after the semester was
/// first uploaded.
Future<CourseResult?> showEditCourseSheet(
  BuildContext context, {
  required GradingScheme scheme,
  CourseResult? initial,
}) {
  var draft = initial == null ? _DraftRow() : _DraftRow.fromResult(initial);
  return showModalBottomSheet<CourseResult?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final palette = sheetContext.palette;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                initial == null ? 'Add a course' : 'Edit course',
                style: TextStyle(color: palette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _RowEditor(
                row: draft,
                scheme: scheme,
                onChanged: (r) => setSheetState(() => draft = r),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: draft.isComplete
                      ? () {
                          final now = DateTime.now();
                          final result = CourseResult(
                            id: initial?.id ?? _uuid.v4(),
                            semesterId: initial?.semesterId ?? '',
                            courseCode: draft.courseCode.trim().toUpperCase(),
                            courseTitle: draft.courseTitle.trim().isEmpty ? null : draft.courseTitle.trim(),
                            creditUnit: draft.creditUnit!,
                            grade: draft.grade!,
                            source: initial?.source ?? ResultSource.manual,
                            extractionConfidence: initial?.extractionConfidence,
                            createdAt: initial?.createdAt ?? now,
                            updatedAt: now,
                          );
                          Navigator.of(sheetContext).pop(result);
                        }
                      : null,
                  child: Text(initial == null ? 'Add course' : 'Save changes'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

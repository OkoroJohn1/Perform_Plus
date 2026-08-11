/// Shared "add a semester" flow for Backfill and Academics/Results. Commits
/// straight to [academicRecordProvider] — kept independent from
/// [onboardingDraftProvider]'s commit path, which still owns the Add
/// Results/GPA reveal flow and has different "who owns this state"
/// semantics.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';

const _uuid = Uuid();

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

Future<void> showAddSemesterSheet(
  BuildContext context, {
  int? initialLevel,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddSemesterSheet(initialLevel: initialLevel),
  );
}

class AddSemesterSheet extends ConsumerStatefulWidget {
  final int? initialLevel;

  const AddSemesterSheet({super.key, this.initialLevel});

  @override
  ConsumerState<AddSemesterSheet> createState() => _AddSemesterSheetState();
}

class _AddSemesterSheetState extends ConsumerState<AddSemesterSheet> {
  late int _level = widget.initialLevel ?? AppConstants.levels.first;
  SemesterTerm _term = SemesterTerm.first;
  late String _session = _currentSession();
  List<_DraftRow> _rows = const [_DraftRow()];

  static String _currentSession() {
    final y = DateTime.now().year;
    return DateTime.now().month >= 9 ? '$y/${y + 1}' : '${y - 1}/$y';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = ref.watch(academicRecordProvider).scheme;
    final canSave = _rows.any((r) => r.isComplete);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
          children: [
            Text('Add a semester', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _level,
                    decoration: const InputDecoration(labelText: 'Level'),
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
                    decoration: const InputDecoration(labelText: 'Semester'),
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
              decoration: const InputDecoration(labelText: 'Session, e.g. 2023/2024'),
              onChanged: (v) => _session = v,
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
                      onPressed: () => setState(() => _rows = [..._rows, const _DraftRow()]),
                      icon: const Icon(Icons.add),
                      label: const Text('Add another course'),
                    );
                  }
                  return _RowEditor(
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
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: canSave ? _save : null,
                child: const Text('Save semester'),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final now = DateTime.now();
    final semesterId = _uuid.v4();

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

    Navigator.of(context).pop();
  }
}

class _RowEditor extends StatelessWidget {
  final _DraftRow row;
  final GradingScheme scheme;
  final ValueChanged<_DraftRow> onChanged;
  final VoidCallback? onRemove;

  const _RowEditor({
    required this.row,
    required this.scheme,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: BorderRadius.circular(12),
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
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: row.grade,
                decoration: const InputDecoration(labelText: 'Grade', isDense: true),
                items: scheme.grades
                    .map((g) => DropdownMenuItem(value: g.letter, child: Text(g.letter)))
                    .toList(),
                onChanged: (v) => onChanged(row.copyWith(grade: v)),
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

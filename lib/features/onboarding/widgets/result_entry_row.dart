import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/onboarding_provider.dart';

/// One editable row in the entry / review table.
/// OCR rows below the confidence threshold get a visible flag so the
/// student checks them rather than trusting a bad extraction.
class ResultEntryRow extends ConsumerWidget {
  final DraftResultRow row;
  final ValueChanged<DraftResultRow> onChanged;
  final VoidCallback? onRemove;

  const ResultEntryRow({
    super.key,
    required this.row,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = ref.watch(onboardingDraftProvider).scheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: row.needsReview
            ? BorderSide(color: theme.colorScheme.tertiary, width: 1.5)
            : BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (row.needsReview)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 16, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 6),
                    Text('Please check this row',
                        style: theme.textTheme.bodySmall),
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
                    decoration: const InputDecoration(
                      labelText: 'Course',
                      isDense: true,
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
                    ),
                    items: List.generate(
                      AppConstants.maxCreditUnit,
                      (i) => DropdownMenuItem(
                          value: i + 1, child: Text('${i + 1}')),
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
                    ),
                    items: scheme.grades
                        .map((g) => DropdownMenuItem(
                              value: g.letter,
                              child: Text('${g.letter} (${g.point})'),
                            ))
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
          ],
        ),
      ),
    );
  }
}

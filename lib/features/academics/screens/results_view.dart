import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/academic_record_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../home/widgets/quick_stats_row.dart';
import '../widgets/add_semester_sheet.dart';

class ResultsView extends ConsumerWidget {
  const ResultsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final standing = ref.watch(standingProvider);
    final record = ref.watch(academicRecordProvider);

    if (!standing.hasData) {
      return EmptyState(
        icon: Icons.list_alt_outlined,
        title: 'No results yet',
        message: 'Add your first semester to see it here.',
        actionLabel: 'Add Result',
        onAction: () => showAddSemesterSheet(context),
      );
    }

    final semesters = [...record.semesters]..sort((a, b) => a.sortKey.compareTo(b.sortKey));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuickStatsRow(standing: standing),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: semesters.length,
              itemBuilder: (context, i) {
                final semester = semesters[i];
                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(semester.label, style: theme.textTheme.titleSmall),
                        const Divider(),
                        ...semester.results.map(
                          (r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(r.courseCode)),
                                Expanded(flex: 1, child: Text('${r.creditUnit}u')),
                                Expanded(flex: 1, child: Text(r.grade)),
                              ],
                            ),
                          ),
                        ),
                        if (semester.results.isEmpty)
                          Text(
                            'No courses in this semester.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          GradientButton.icon(
            onPressed: () => showAddSemesterSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Result'),
          ),
        ],
      ),
    );
  }
}

/// Backfill prompt. Skippable and resumable; never a hard gate.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../academics/widgets/add_semester_sheet.dart';

class BackfillScreen extends ConsumerWidget {
  const BackfillScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final record = ref.watch(academicRecordProvider);
    final addedLevels =
        record.semesters.map((s) => s.level).toSet();
    final addedCount = AppConstants.levels.where(addedLevels.contains).length;

    return GradientScaffold(
      appBar: AppBar(title: const Text('Add earlier semesters')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add your previous semesters to get better insights',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '$addedCount of ${AppConstants.levels.length} semesters added',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: addedCount / AppConstants.levels.length,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: AppConstants.levels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final level = AppConstants.levels[i];
                    final added = addedLevels.contains(level);
                    return GlassCard(
                      child: ListTile(
                        leading: Icon(
                          added ? Icons.check_circle : Icons.circle_outlined,
                          color: added
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                        title: Text('$level Level'),
                        trailing: added
                            ? Text('Added',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ))
                            : OutlinedButton(
                                onPressed: () =>
                                    showAddSemesterSheet(context, initialLevel: level),
                                child: const Text('Add'),
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onPressed: () => context.go(Routes.goalSetting),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => context.go(Routes.goalSetting),
                  child: const Text('Skip for now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

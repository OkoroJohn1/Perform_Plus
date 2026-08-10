/// Study tab. The reading timer is the only DAILY hook in V1 — the core
/// CGPA loop fires roughly twice a year, which is uninstall territory
/// without something that earns a daily open. Everything else here
/// (Notes, Flashcards, Exam Prep, Study Planner) is V2.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/locked_feature_row.dart';
import '../providers/reading_session_provider.dart';

class StudyShell extends ConsumerWidget {
  const StudyShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reading = ref.watch(readingSessionProvider);
    final controller = ref.read(readingSessionProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Study')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text('Reading timer', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Text(
                      _formatDuration(reading.todayElapsed),
                      style: theme.textTheme.displayMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: reading.isRunning ? controller.pause : controller.start,
                      icon: Icon(reading.isRunning ? Icons.pause : Icons.play_arrow),
                      label: Text(reading.isRunning ? 'Pause' : 'Start reading'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_fire_department,
                            size: 18, color: theme.colorScheme.tertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${reading.currentStreakDays} day streak',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const LockedFeatureRow(
              icon: Icons.note_alt_outlined,
              title: 'Notes',
              subtitle: 'Upload notes and get instant summaries',
            ),
            const LockedFeatureRow(
              icon: Icons.style_outlined,
              title: 'Flashcards',
              subtitle: 'Generated from your notes',
            ),
            const LockedFeatureRow(
              icon: Icons.quiz_outlined,
              title: 'Exam Preparation',
              subtitle: 'Practice quizzes from past questions',
            ),
            const LockedFeatureRow(
              icon: Icons.event_note_outlined,
              title: 'Study Planner',
              subtitle: 'A plan built around your exam dates',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

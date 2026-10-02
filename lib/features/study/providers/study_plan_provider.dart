/// Today's plan — a note plus a target page count for the day. No AI
/// scheduling (that needs the backend); manual entry only in V1. Not one of
/// the task's named Drift tables, so this stays in-memory like the old
/// reading-session provider did before this rebuild — it resets on
/// restart, a reasonable trade for a feature this small.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudyPlanTask {
  final String noteId;
  final String noteTitle;
  final int targetPages;

  const StudyPlanTask({required this.noteId, required this.noteTitle, required this.targetPages});
}

class StudyPlanController extends StateNotifier<List<StudyPlanTask>> {
  StudyPlanController() : super(const []);

  void add(StudyPlanTask task) => state = [...state, task];

  void removeAt(int index) => state = [
        for (var i = 0; i < state.length; i++)
          if (i != index) state[i],
      ];

  void clear() => state = const [];
}

final studyPlanProvider = StateNotifierProvider<StudyPlanController, List<StudyPlanTask>>(
  (ref) => StudyPlanController(),
);

/// Builds the JSON payload behind the settings screen's "Export your data"
/// row. Pure Dart -- no I/O, no BuildContext -- so the shape of the export
/// is directly unit-testable without touching the filesystem or the share
/// sheet. Works fully offline: every field here is already in Drift.
library;

import '../../../data/repositories/academic_record_provider.dart';
import '../../../domain/models/goal_target.dart';
import '../../../domain/models/note.dart';
import '../../auth/providers/profile_provider.dart';

Map<String, dynamic> buildExportPayload({
  required StudentProfile? profile,
  required AcademicRecord record,
  required List<Note> notes,
  required Map<String, int> pagesReadByNote,
  required GoalTarget? goal,
}) {
  return {
    'exportedAt': DateTime.now().toIso8601String(),
    'profile': profile == null
        ? null
        : {
            'fullName': profile.fullName,
            'regNumber': profile.regNumber,
            'department': profile.department,
            'currentLevel': profile.currentLevel,
            'entryYear': profile.entryYear,
            'expectedGraduationYear': profile.expectedGraduationYear,
          },
    'scheme': {
      'name': record.scheme.name,
      'maxPoint': record.scheme.maxPoint,
      'repeatPolicy': record.scheme.repeatPolicy.name,
    },
    'semesters': [
      for (final s in record.semesters)
        {
          'session': s.session,
          'term': s.term.name,
          'level': s.level,
          'results': [
            for (final r in s.results)
              {'courseCode': r.courseCode, 'creditUnit': r.creditUnit, 'grade': r.grade},
          ],
        },
    ],
    'goal': goal == null
        ? null
        : {
            'classification': goal.band.shortLabel,
            'semestersRemaining': goal.semestersRemaining,
          },
    'notes': [
      for (final n in notes)
        {
          'title': n.title,
          'category': n.category.name,
          'totalPages': n.totalPages,
          'pagesRead': pagesReadByNote[n.id] ?? 0,
        },
    ],
  };
}

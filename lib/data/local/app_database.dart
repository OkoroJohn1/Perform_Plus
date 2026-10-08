/// The local SQLite database — source of truth for offline-first academic
/// records. See AGENTS.md: the CGPA engine is pure computation and must
/// run with zero network, so this is where everything actually lives until
/// a Supabase mirror is added.
library;

import 'package:drift/drift.dart';

import '../../domain/models/achievement.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/models/course_result.dart';
import '../../domain/models/grading_scheme.dart';
import '../../domain/models/note.dart';
import 'connection/connection_unsupported.dart'
    if (dart.library.io) 'connection/connection_native.dart'
    if (dart.library.js_interop) 'connection/connection_web.dart'
    as platform;
import 'converters/classification_band_list_converter.dart';
import 'converters/grade_definition_list_converter.dart';
import 'converters/string_map_converter.dart';
import 'daos/achievement_dao.dart';
import 'daos/calendar_mark_dao.dart';
import 'daos/course_result_dao.dart';
import 'daos/goal_dao.dart';
import 'daos/grading_scheme_dao.dart';
import 'daos/local_settings_dao.dart';
import 'daos/note_dao.dart';
import 'daos/notification_dao.dart';
import 'daos/profile_dao.dart';
import 'daos/semester_dao.dart';
import 'daos/slip_upload_dao.dart';
import 'tables/achievements_table.dart';
import 'tables/calendar_marks_table.dart';
import 'tables/course_results_table.dart';
import 'tables/goals_table.dart';
import 'tables/grading_schemes_table.dart';
import 'tables/local_settings_table.dart';
import 'tables/note_pages_table.dart';
import 'tables/notes_table.dart';
import 'tables/notifications_table.dart';
import 'tables/profiles_table.dart';
import 'tables/reading_sessions_table.dart';
import 'tables/semesters_table.dart';
import 'tables/slip_uploads_table.dart';
import 'tables/study_streak_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Profiles,
    Semesters,
    CourseResults,
    GradingSchemes,
    Goals,
    Notes,
    NotePages,
    ReadingSessions,
    StudyStreaks,
    Achievements,
    Notifications,
    LocalSettings,
    CalendarMarks,
    SlipUploads,
  ],
  daos: [
    ProfileDao,
    SemesterDao,
    CourseResultDao,
    GradingSchemeDao,
    GoalDao,
    NoteDao,
    AchievementDao,
    NotificationDao,
    LocalSettingsDao,
    CalendarMarkDao,
    SlipUploadDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(platform.connect());

  /// For tests: pass `NativeDatabase.memory()` (or any `QueryExecutor`) so
  /// nothing touches the real filesystem/platform channels.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          // v1 -> v2: institution setup's "unverified default scheme"
          // warning needs a column to key off.
          if (from < 2) {
            await m.addColumn(gradingSchemes, gradingSchemes.isVerified);
          }
          // v2 -> v3: add-results' session selector reads term names (e.g.
          // FUTO's Harmattan/Rain) off the scheme instead of hardcoding them.
          if (from < 3) {
            await m.addColumn(gradingSchemes, gradingSchemes.firstTermLabel);
            await m.addColumn(gradingSchemes, gradingSchemes.secondTermLabel);
          }
          // v3 -> v4: profile setup adds a faculty field and an optional
          // local profile photo.
          if (from < 4) {
            await m.addColumn(profiles, profiles.faculty);
            await m.addColumn(profiles, profiles.photoPath);
          }
          // v4 -> v5: the Study tab's e-notes reader.
          if (from < 5) {
            await m.createTable(notes);
            await m.createTable(notePages);
            await m.createTable(readingSessions);
            await m.createTable(studyStreaks);
          }
          // v5 -> v6: the Me tab's achievement badges.
          if (from < 6) {
            await m.createTable(achievements);
          }
          // v6 -> v7: the notifications panel.
          if (from < 7) {
            await m.createTable(notifications);
          }
          // v7 -> v8: the settings screen's Appearance row -- a generic
          // key-value table now that theme mode actually needs to persist.
          if (from < 8) {
            await m.createTable(localSettings);
          }
          // v8 -> v9: the Study tab's markable calendar.
          if (from < 9) {
            await m.createTable(calendarMarks);
          }
          // v9 -> v10: notes back up to Supabase Storage in the
          // background -- this tracks whether/where a note's file landed.
          if (from < 10) {
            await m.addColumn(notes, notes.storagePath);
          }
          // v10 -> v11: the Result slip wallet on the Results screen.
          if (from < 11) {
            await m.createTable(slipUploads);
          }
          // v11 -> v12: a second, opt-in cumulative-CGPA aggregation mode
          // (Me tab's Grading scheme sheet) -- see
          // `GradingScheme.cgpaAggregation`'s doc comment. Every existing
          // row gets the column's own default (creditWeighted, the
          // standard method), never silently switched to the other one.
          if (from < 12) {
            await m.addColumn(gradingSchemes, gradingSchemes.cgpaAggregation);
          }
        },
      );

  /// The destructive half of Me's sign-out flow — see the two-tier
  /// confirmation in `me_shell.dart`. Deletes everything the student
  /// entered for [profileId]: semesters (and their course results), notes
  /// (and their pages/reading sessions), goals, the study streak,
  /// achievements and notifications. Grading scheme rows are left alone —
  /// they're reusable reference data (a scheme snapshot), not personal
  /// data, and re-seed on the next onboarding pass regardless.
  Future<void> wipeLocalData(String profileId) {
    return transaction(() async {
      final semesterIds = await (select(semesters)..where((s) => s.profileId.equals(profileId)))
          .map((s) => s.id)
          .get();
      if (semesterIds.isNotEmpty) {
        await (delete(courseResults)..where((c) => c.semesterId.isIn(semesterIds))).go();
      }
      await (delete(semesters)..where((s) => s.profileId.equals(profileId))).go();

      final noteIds =
          await (select(notes)..where((n) => n.profileId.equals(profileId))).map((n) => n.id).get();
      if (noteIds.isNotEmpty) {
        await (delete(notePages)..where((p) => p.noteId.isIn(noteIds))).go();
        await (delete(readingSessions)..where((r) => r.noteId.isIn(noteIds))).go();
      }
      await (delete(notes)..where((n) => n.profileId.equals(profileId))).go();

      await (delete(goals)..where((g) => g.profileId.equals(profileId))).go();
      await (delete(studyStreaks)..where((s) => s.profileId.equals(profileId))).go();
      await (delete(achievements)..where((a) => a.profileId.equals(profileId))).go();
      await (delete(notifications)..where((n) => n.profileId.equals(profileId))).go();
      await (delete(calendarMarks)..where((c) => c.profileId.equals(profileId))).go();
      await (delete(slipUploads)..where((s) => s.profileId.equals(profileId))).go();
      await (delete(profiles)..where((p) => p.id.equals(profileId))).go();
    });
  }
}

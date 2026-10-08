/// The whole persistence-layer dependency graph in one place: the database
/// instance and the four repository providers. Screens/other providers
/// depend on the `Provider<XRepository>`s here, never on `AppDatabase` or
/// Drift types directly — this is the single swap point when a remote-sync
/// repository is added later.
///
/// Any widget test that touches this provider tree must override
/// [appDatabaseProvider] with `AppDatabase.forTesting(NativeDatabase.memory())`
/// — the real constructor hits platform channels (`path_provider`) and will
/// throw/hang in a plain `flutter test` run.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/notifications/local_notification_service.dart';
import '../../domain/repositories/academic_record_repository.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/grading_scheme_repository.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/slip_wallet_repository.dart';
import '../local/app_database.dart';
import 'drift_academic_record_repository.dart';
import 'drift_achievement_repository.dart';
import 'drift_calendar_repository.dart';
import 'drift_goal_repository.dart';
import 'drift_grading_scheme_repository.dart';
import 'drift_note_repository.dart';
import 'drift_notification_repository.dart';
import 'drift_profile_repository.dart';
import 'drift_slip_wallet_repository.dart';
import 'note_remote_sync.dart';
import 'profile_photo_remote_sync.dart';
import 'profile_remote_sync.dart';
import 'security_questions_remote_sync.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final academicRecordRepositoryProvider = Provider<AcademicRecordRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftAcademicRecordRepository(db.semesterDao, db.courseResultDao);
});

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => DriftProfileRepository(ref.watch(appDatabaseProvider).profileDao),
);

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => DriftGoalRepository(ref.watch(appDatabaseProvider).goalDao),
);

final gradingSchemeRepositoryProvider = Provider<GradingSchemeRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftGradingSchemeRepository(db.gradingSchemeDao, db.profileDao);
});

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => DriftNoteRepository(ref.watch(appDatabaseProvider).noteDao),
);

final achievementRepositoryProvider = Provider<AchievementRepository>(
  (ref) => DriftAchievementRepository(ref.watch(appDatabaseProvider).achievementDao),
);

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => DriftCalendarRepository(ref.watch(appDatabaseProvider).calendarMarkDao),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => DriftNotificationRepository(ref.watch(appDatabaseProvider).notificationDao),
);

final slipWalletRepositoryProvider = Provider<SlipWalletRepository>(
  (ref) => DriftSlipWalletRepository(ref.watch(appDatabaseProvider).slipUploadDao),
);

/// A plain, test-safe singleton (every call internally swallows platform-
/// channel errors -- see its own doc comment), so unlike the Supabase-
/// backed `null`-guarded providers above, this never needs try/catch here.
final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => LocalNotificationService(),
);

/// A generic key-value DAO, not a domain concept -- exposed directly
/// rather than wrapped in a repository interface like the rest of this
/// file, since there's nothing here for a fake implementation to abstract
/// over. See `theme_mode_provider.dart`, its only consumer.
final localSettingsDaoProvider = Provider((ref) => ref.watch(appDatabaseProvider).localSettingsDao);

final profileRemoteSyncProvider = Provider<ProfileRemoteSync>(
  (ref) => SupabaseProfileRemoteSync(Supabase.instance.client),
);

/// `null` when Supabase was never initialized -- every plain `flutter test`
/// run, since `Supabase.instance.client` throws synchronously rather than
/// surfacing as an awaitable error the way an uninitialized
/// `AsyncNotifierProvider` does. `notesProvider` (a widely-depended-on
/// provider touched by many unrelated widget tests) watches this
/// unconditionally, so it must never throw just because a test has no
/// reason to care about Supabase at all.
final noteRemoteSyncProvider = Provider<NoteRemoteSync?>((ref) {
  try {
    return SupabaseNoteRemoteSync(Supabase.instance.client);
  } catch (_) {
    return null;
  }
});

/// Same "`null` when Supabase was never initialized" guard as
/// [noteRemoteSyncProvider] above -- `profileProvider`'s controller reads
/// this on every cold start (to check whether a locally-missing photo file
/// can be restored), so it must never throw in a plain `flutter test` run.
final profilePhotoRemoteSyncProvider = Provider<ProfilePhotoRemoteSync?>((ref) {
  try {
    return SupabaseProfilePhotoRemoteSync(Supabase.instance.client);
  } catch (_) {
    return null;
  }
});

/// Same "`null` when Supabase was never initialized" guard as the two
/// providers above.
final securityQuestionsRemoteSyncProvider = Provider<SecurityQuestionsRemoteSync?>((ref) {
  try {
    return SupabaseSecurityQuestionsRemoteSync(Supabase.instance.client);
  } catch (_) {
    return null;
  }
});

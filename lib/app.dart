import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_accent_provider.dart';
import 'core/theme/theme_mode_provider.dart';
import 'data/repositories/academic_record_provider.dart';
import 'data/repositories/achievement_provider.dart';
import 'data/repositories/note_provider.dart';
import 'data/repositories/notification_provider.dart';
import 'features/auth/providers/pin_provider.dart';
import 'features/auth/screens/pin_lock_screen.dart';

class PerformPlusApp extends ConsumerStatefulWidget {
  const PerformPlusApp({super.key});

  @override
  ConsumerState<PerformPlusApp> createState() => _PerformPlusAppState();
}

/// A badge like [BadgeId.consistentLearner] depends on the reading streak,
/// which can flip purely from a day rolling over while the app was closed
/// -- no new write to react to. Registered here, not in `me_shell.dart`,
/// because achievements should be evaluated regardless of which tab is on
/// screen when the app resumes.
class _PerformPlusAppState extends ConsumerState<PerformPlusApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(achievementsProvider.notifier).evaluate();
      // Only re-locks if the background actually lasted the configured
      // auto-lock window -- see `pin_provider.dart`'s doc comment. A raw
      // "lock on every pause" used to also fire for the system
      // camera/share sheet/file picker taking the foreground momentarily,
      // which cost `profile_setup_screen.dart`'s in-flight photo pick its
      // result the instant the student returned.
      ref.read(pinProvider.notifier).handleResume();
      // Covers a student who resumes into a tab other than Home for the
      // rest of the day -- `dashboard_screen.dart`'s own check only fires
      // when that screen actually mounts. See
      // `NotificationsController.maybeGenerateDailyReminder`'s doc comment.
      ref.read(notificationsProvider.notifier).maybeGenerateDailyReminder(
            standing: ref.read(standingProvider),
            notes: ref.read(notesProvider).notes,
          );
    } else if (state == AppLifecycleState.paused) {
      ref.read(pinProvider.notifier).handlePause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(themeAccentProvider);
    final pinState = ref.watch(pinProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accent),
      darkTheme: AppTheme.dark(accent: accent),
      themeMode: themeMode,
      routerConfig: router,
      // Sits above the router entirely -- no route-stack manipulation, and
      // no back-gesture escape from it. `pinState.loaded` guards against a
      // one-frame flash of the lock screen before the async secure-storage
      // read (in `PinController._load`) resolves.
      builder: (context, child) {
        if (pinState.loaded && pinState.shouldLock) {
          return const PinLockScreen();
        }
        return child!;
      },
    );
  }
}

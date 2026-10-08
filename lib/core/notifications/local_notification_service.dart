/// Real OS-level local notifications -- the daily study/CGPA reminders show
/// in the phone's own notification shade, not only inside the app's
/// Notifications panel. `flutter_local_notifications` + `timezone` were
/// already carried as dependencies for exactly this (see `pubspec.yaml`'s
/// comment) but never wired up until now.
///
/// There is no backend/FCM push server in this project (AGENTS.md: local-
/// first, offline-capable) -- every reminder here is scheduled from the
/// device itself, which means the app must be opened or resumed at least
/// once that day for that day's reminders to be scheduled. That's an
/// honest limitation of a local-only app, not a bug: see
/// `NotificationsController.maybeGenerateDailyReminder`'s doc comment.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _channelId = 'daily_reminders';
const _channelName = 'Daily reminders';
const _channelDescription = 'Study and CGPA reminders, up to a few times a day.';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Every public method below is best-effort and swallows its own errors
  /// -- there's no real platform channel handler in a plain `flutter test`
  /// run (no device/emulator), and a reminder notification is never worth
  /// crashing a screen over. Same convention as `deleteProfilePhotoFile`
  /// elsewhere in this codebase.
  Future<bool> _ensureReady() async {
    if (_ready) return true;
    try {
      tz_data.initializeTimeZones();
      // This app's seeded institutions are all Nigerian (AGENTS.md) -- a
      // single fixed zone (no DST, unlike pulling in a device-timezone
      // plugin just for this) is an honest simplification, not a guess.
      tz.setLocalLocation(tz.getLocation('Africa/Lagos'));

      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.defaultImportance,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _ready = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName, channelDescription: _channelDescription),
        iOS: DarwinNotificationDetails(),
      );

  Future<void> showNow({required int id, required String title, required String body}) async {
    if (!await _ensureReady()) return;
    try {
      await _plugin.show(id, title, body, _details);
    } catch (_) {
      // Best-effort -- see this class's doc comment.
    }
  }

  /// One-shot scheduled notification for a specific future moment today --
  /// never a repeating alarm, since each day's content (today's real CGPA,
  /// the note actually being read) is only known once the app has run that
  /// day and can't be pre-computed further ahead than that.
  Future<void> scheduleOneOff({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!await _ensureReady()) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        _details,
        // Inexact: avoids requesting Android 12+'s separate "exact alarm"
        // permission for a reminder that's fine landing within a few
        // minutes of its target time.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // iOS-only legacy parameter the plugin still requires on its
        // unified API -- absoluteTime means "the wall-clock moment we
        // computed", not "N seconds from now."
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Best-effort -- see this class's doc comment.
    }
  }

  Future<void> cancelAll() async {
    if (!await _ensureReady()) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Best-effort -- see this class's doc comment.
    }
  }
}

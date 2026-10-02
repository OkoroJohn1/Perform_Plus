/// Whether the OS notification permission is granted — behind an
/// interface so tests can drive the panel's permission-aware hero banner
/// without touching the real `permission_handler` platform channel.
library;

import 'package:permission_handler/permission_handler.dart';

abstract class NotificationPermissionChecker {
  Future<bool> isGranted();

  /// Requests the system permission; returns whether it ended up granted.
  Future<bool> request();
}

class SystemNotificationPermissionChecker implements NotificationPermissionChecker {
  const SystemNotificationPermissionChecker();

  @override
  Future<bool> isGranted() async => (await Permission.notification.status).isGranted;

  @override
  Future<bool> request() async => (await Permission.notification.request()).isGranted;
}

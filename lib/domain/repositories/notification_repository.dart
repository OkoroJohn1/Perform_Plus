/// Abstract interface only — see `academic_record_repository.dart` for the
/// purity rationale.
library;

import '../models/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> loadAll();
  Future<void> add(AppNotification notification);
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> delete(String id);

  /// Deletes everything older than [notificationRetention] — call once on
  /// app start, never on every read.
  Future<void> pruneOld();
}

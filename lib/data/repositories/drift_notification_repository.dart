/// Drift-backed [NotificationRepository].
library;

import 'package:drift/drift.dart' show Value;

import '../../core/constants/app_constants.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../local/app_database.dart';
import '../local/daos/notification_dao.dart';

class DriftNotificationRepository implements NotificationRepository {
  final NotificationDao _dao;

  DriftNotificationRepository(this._dao);

  AppNotification _fromRow(NotificationRow row) => AppNotification(
        id: row.id,
        type: row.type,
        title: row.title,
        body: row.body,
        payload: row.payload,
        createdAt: row.createdAt,
        readAt: row.readAt,
      );

  @override
  Future<List<AppNotification>> loadAll() async {
    final rows = await _dao.getAll(AppConstants.localProfileId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> add(AppNotification notification) => _dao.insert(
        NotificationsCompanion.insert(
          id: notification.id,
          profileId: AppConstants.localProfileId,
          type: notification.type,
          title: notification.title,
          body: notification.body,
          payload: Value(notification.payload),
          createdAt: notification.createdAt,
          readAt: Value(notification.readAt),
        ),
      );

  @override
  Future<void> markRead(String id) => _dao.markRead(id, DateTime.now());

  @override
  Future<void> markAllRead() => _dao.markAllRead(AppConstants.localProfileId, DateTime.now());

  @override
  Future<void> delete(String id) => _dao.deleteById(id);

  @override
  Future<void> pruneOld() => _dao.deleteCreatedBefore(
        AppConstants.localProfileId,
        DateTime.now().subtract(notificationRetention),
      );
}

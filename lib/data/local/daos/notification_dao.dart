import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/notifications_table.dart';

part 'notification_dao.g.dart';

@DriftAccessor(tables: [Notifications])
class NotificationDao extends DatabaseAccessor<AppDatabase> with _$NotificationDaoMixin {
  NotificationDao(super.db);

  Future<List<NotificationRow>> getAll(String profileId) =>
      (select(notifications)
            ..where((n) => n.profileId.equals(profileId))
            ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
          .get();

  Future<void> insert(NotificationsCompanion entry) => into(notifications).insert(entry);

  Future<void> markRead(String id, DateTime readAt) =>
      (update(notifications)..where((n) => n.id.equals(id)))
          .write(NotificationsCompanion(readAt: Value(readAt)));

  Future<void> markAllRead(String profileId, DateTime readAt) => (update(notifications)
        ..where((n) => n.profileId.equals(profileId) & n.readAt.isNull()))
      .write(NotificationsCompanion(readAt: Value(readAt)));

  Future<void> deleteById(String id) =>
      (delete(notifications)..where((n) => n.id.equals(id))).go();

  Future<void> deleteCreatedBefore(String profileId, DateTime cutoff) =>
      (delete(notifications)
            ..where((n) => n.profileId.equals(profileId) & n.createdAt.isSmallerThanValue(cutoff)))
          .go();
}

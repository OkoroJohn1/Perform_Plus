import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/achievement.dart';
import '../app_database.dart';
import '../tables/achievements_table.dart';

part 'achievement_dao.g.dart';

const _uuid = Uuid();

@DriftAccessor(tables: [Achievements])
class AchievementDao extends DatabaseAccessor<AppDatabase> with _$AchievementDaoMixin {
  AchievementDao(super.db);

  Future<List<AchievementRow>> getAll(String profileId) =>
      (select(achievements)..where((a) => a.profileId.equals(profileId))).get();

  /// No-op if [badgeId] is already unlocked for this profile — the table
  /// has no unique constraint on (profileId, badgeId) since its primary
  /// key is a synthetic id, so this check lives at the app layer instead.
  Future<void> unlockIfNew(String profileId, BadgeId badgeId, DateTime unlockedAt) async {
    final existing = await (select(achievements)
          ..where((a) => a.profileId.equals(profileId) & a.badgeId.equalsValue(badgeId)))
        .getSingleOrNull();
    if (existing != null) return;

    await into(achievements).insert(
      AchievementsCompanion.insert(
        id: _uuid.v4(),
        profileId: profileId,
        badgeId: badgeId,
        unlockedAt: unlockedAt,
      ),
    );
  }
}

/// Drift-backed [AchievementRepository].
library;

import '../../core/constants/app_constants.dart';
import '../../domain/models/achievement.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../local/daos/achievement_dao.dart';

class DriftAchievementRepository implements AchievementRepository {
  final AchievementDao _dao;

  DriftAchievementRepository(this._dao);

  @override
  Future<Map<BadgeId, DateTime>> loadUnlocked() async {
    final rows = await _dao.getAll(AppConstants.localProfileId);
    return {for (final r in rows) r.badgeId: r.unlockedAt};
  }

  @override
  Future<void> unlockIfNew(BadgeId badgeId, DateTime unlockedAt) =>
      _dao.unlockIfNew(AppConstants.localProfileId, badgeId, unlockedAt);
}

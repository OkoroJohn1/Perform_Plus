/// Abstract interface only — see `academic_record_repository.dart` for the
/// purity rationale.
library;

import '../models/achievement.dart';

abstract class AchievementRepository {
  Future<Map<BadgeId, DateTime>> loadUnlocked();
  Future<void> unlockIfNew(BadgeId badgeId, DateTime unlockedAt);
}

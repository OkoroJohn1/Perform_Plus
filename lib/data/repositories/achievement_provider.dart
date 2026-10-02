/// Achievement state — unlocked badges plus when each was earned.
///
/// Triggers are evaluated on app resume and whenever the data they depend
/// on changes (a result is written, a reading session is logged) — never
/// on every widget build. This controller reacts to [standingProvider] and
/// [notesProvider] via `ref.listen` (registered once, in the constructor,
/// same pattern as `AcademicRecordController`'s draft listener) rather than
/// being re-evaluated from a build method; `evaluate()` is also exposed
/// directly for the app-resume hook (see `me_shell.dart`).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/engine/achievement_engine.dart';
import '../../domain/models/achievement.dart';
import '../../domain/repositories/achievement_repository.dart';
import 'academic_record_provider.dart';
import 'note_provider.dart';
import 'repository_providers.dart';

class AchievementsController extends StateNotifier<Map<BadgeId, DateTime>> {
  final Ref? _ref;
  final AchievementRepository? _repository;

  late final Future<void> ready;

  AchievementsController(Ref ref, AchievementRepository repository)
      : _ref = ref,
        _repository = repository,
        super(const {}) {
    ready = _load();
    ref.listen(standingProvider, (_, __) => evaluate());
    ref.listen(notesProvider, (_, __) => evaluate());
  }

  /// Fixed-state constructor for widget tests — no reactive evaluation, no
  /// repository writes.
  AchievementsController.seeded(super.state)
      : _ref = null,
        _repository = null {
    ready = Future.value();
  }

  Future<void> _load() async {
    final repo = _repository;
    if (repo == null) return;
    state = await repo.loadUnlocked();
    await evaluate();
  }

  Future<void> evaluate() async {
    final ref = _ref;
    final repo = _repository;
    if (ref == null || repo == null) return;

    final standing = ref.read(standingProvider);
    final streak = ref.read(notesProvider).displayStreak;
    final earned = evaluateEarnedBadges(standing: standing, currentStreak: streak);

    final newlyEarned = earned.where((b) => !state.containsKey(b));
    if (newlyEarned.isEmpty) return;

    final now = DateTime.now();
    final next = {...state};
    for (final badge in newlyEarned) {
      next[badge] = now;
      unawaited(repo.unlockIfNew(badge, now));
    }
    state = next;
  }
}

final achievementsProvider = StateNotifierProvider<AchievementsController, Map<BadgeId, DateTime>>(
  (ref) => AchievementsController(ref, ref.watch(achievementRepositoryProvider)),
);

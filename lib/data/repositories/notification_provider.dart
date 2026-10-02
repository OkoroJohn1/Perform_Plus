/// Notification state — generated locally from real app events, stored in
/// Drift. Every generation site below corresponds to exactly one of the
/// triggers named in the task brief; nothing fires speculatively.
///
/// Reactive generation (`ref.listen`, registered once in the constructor —
/// same pattern as `AcademicRecordController`'s draft listener) covers
/// "after any result... is written" without re-evaluating on every widget
/// build. `unreadCount` backs the header bell badge on every tab; marking
/// read/all-read updates it immediately since it's derived from `state`,
/// not a separate cached flag.
library;

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/seed/nigerian_institutions.dart';
import '../../domain/engine/cgpa_engine.dart';
import '../../domain/engine/projection_solver.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/models/course_result.dart';
import '../../domain/models/grading_scheme.dart';
import '../../domain/repositories/notification_repository.dart';
import 'academic_record_provider.dart';
import 'achievement_provider.dart';
import 'goal_provider.dart';
import 'repository_providers.dart';

const _uuid = Uuid();

class NotificationsController extends StateNotifier<List<AppNotification>> {
  final NotificationRepository? _repository;

  late final Future<void> ready;

  NotificationsController(Ref ref, NotificationRepository repository)
      : _repository = repository,
        super(const []) {
    ready = _init();
    ref.listen(academicRecordProvider, _onRecordChanged);
    ref.listen<TargetProjection?>(targetProjectionProvider, _onProjectionChanged);
    ref.listen(achievementsProvider, _onAchievementsChanged);
  }

  /// Fixed-state constructor for widget tests — no reactive generation, no
  /// repository writes.
  NotificationsController.seeded(super.state) : _repository = null {
    ready = Future.value();
  }

  Future<void> _init() async {
    final repo = _repository;
    if (repo == null) return;
    await repo.pruneOld();
    state = await repo.loadAll();
  }

  int get unreadCount => state.where((n) => !n.isRead).length;

  Future<void> markRead(String id) async {
    state = [for (final n in state) n.id == id ? n.copyWith(readAt: DateTime.now()) : n];
    await _repository?.markRead(id);
  }

  Future<void> markAllRead() async {
    final now = DateTime.now();
    state = [for (final n in state) n.isRead ? n : n.copyWith(readAt: now)];
    await _repository?.markAllRead();
  }

  /// Returns the removed notification so the caller can offer Undo.
  Future<AppNotification> dismiss(String id) async {
    final removed = state.firstWhere((n) => n.id == id);
    state = state.where((n) => n.id != id).toList();
    await _repository?.delete(id);
    return removed;
  }

  Future<void> restore(AppNotification notification) async {
    state = [notification, ...state]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _repository?.add(notification);
  }

  Future<void> _add({
    required AppNotificationType type,
    required String title,
    required String body,
    Map<String, String> payload = const {},
  }) async {
    final notification = AppNotification(
      id: _uuid.v4(),
      type: type,
      title: title,
      body: body,
      payload: payload,
      createdAt: DateTime.now(),
    );
    state = [notification, ...state];
    unawaited(_repository?.add(notification));
  }

  String _institutionName(GradingScheme scheme) =>
      nigerianInstitutions.firstWhereOrNull((i) => i.id == scheme.institutionId)?.name ??
      scheme.name;

  /// Fires "result added", "CGPA changed" and any newly-appearing
  /// "carryover flagged" notifications when a new semester is committed.
  void _onRecordChanged(AcademicRecord? previous, AcademicRecord next) {
    if (previous == null || next.semesters.length <= previous.semesters.length) return;

    final prevStanding =
        CgpaEngine.computeStanding(semesters: previous.semesters, scheme: previous.scheme);
    final nextStanding = CgpaEngine.computeStanding(semesters: next.semesters, scheme: next.scheme);

    final added = [...next.semesters]..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    final newest = added.last;

    final result = resultAddedContent(
      scheme: next.scheme,
      level: newest.level,
      term: newest.term,
      cgpa: nextStanding.cgpa,
    );
    unawaited(_add(type: AppNotificationType.resultAdded, title: result.title, body: result.body));

    final delta = CgpaEngine.round2(nextStanding.cgpa - prevStanding.cgpa);
    final cgpa = cgpaChangedContent(
      scheme: next.scheme,
      level: newest.level,
      term: newest.term,
      delta: delta,
      cgpa: nextStanding.cgpa,
    );
    unawaited(_add(
      type: AppNotificationType.cgpaChanged,
      title: cgpa.title,
      body: cgpa.body,
      payload: {'rising': cgpa.rising.toString()},
    ));

    final excludedIds = <String>{};
    for (final comp in nextStanding.semesters) {
      excludedIds.addAll(comp.excluded.map((e) => e.resultId));
    }
    final byCode = <String, List<CourseResult>>{};
    for (final r in newest.results) {
      byCode.putIfAbsent(r.courseCode, () => []).add(r);
    }
    final institutionName = _institutionName(next.scheme);
    final policy = switch (next.scheme.repeatPolicy) {
      RepeatPolicy.countBothAttempts => 'both attempts count toward your CGPA',
      RepeatPolicy.replaceOriginal => 'your retake replaces the original grade',
      RepeatPolicy.replaceWithCap =>
        'retakes cap at ${next.scheme.repeatCapPoint?.toStringAsFixed(1) ?? '—'} points',
    };
    for (final entry in byCode.entries) {
      final isCarryover = entry.value.length > 1 ||
          (!excludedIds.contains(entry.value.single.id) &&
              next.scheme.isFailingLetter(entry.value.single.grade));
      if (!isCarryover) continue;
      final carryover = carryoverFlaggedContent(
        courseCode: entry.key,
        institutionName: institutionName,
        policyDescription: policy,
      );
      unawaited(_add(
        type: AppNotificationType.carryoverFlagged,
        title: carryover.title,
        body: carryover.body,
      ));
    }
  }

  /// Fires "goal pace changed" when feasibility moves to a different
  /// category — not on every recomputation with the same category.
  void _onProjectionChanged(TargetProjection? previous, TargetProjection? next) {
    if (previous == null || next == null) return;
    if (previous.feasibility == next.feasibility) return;
    final required = next.requiredAverage;
    if (required == null) return;

    final content = goalPaceChangedContent(
      requiredAverage: required,
      bandLabel: next.targetLabel ?? 'Your goal',
      semestersRemaining: next.semestersRemaining,
    );
    unawaited(
      _add(type: AppNotificationType.goalPaceChanged, title: content.title, body: content.body),
    );
  }

  void _onAchievementsChanged(Map<BadgeId, DateTime>? previous, Map<BadgeId, DateTime> next) {
    if (previous == null) return;
    final newlyEarned = next.keys.toSet().difference(previous.keys.toSet());
    for (final badgeId in newlyEarned) {
      final definition = allBadges.firstWhere((b) => b.id == badgeId);
      final content = achievementUnlockedContent(
        badgeName: definition.name,
        criteria: definition.criteria,
      );
      unawaited(_add(
        type: AppNotificationType.achievementUnlocked,
        title: content.title,
        body: content.body,
      ));
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsController, List<AppNotification>>(
  (ref) => NotificationsController(ref, ref.watch(notificationRepositoryProvider)),
);

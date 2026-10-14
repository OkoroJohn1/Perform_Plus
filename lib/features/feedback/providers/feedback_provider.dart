/// State for the Feedback tab: the shared feed, submission state, and the
/// client-side half of the 24-hour re-ask cadence (`_lastSubmittedAtKey`,
/// `local_settings` — same lightweight key-value pattern already used for
/// `pinPromptDismissed`/`themeAccent`). The real, un-bypassable 24h limit is
/// enforced server-side (see `SupabaseFeedbackRepository`'s doc comment);
/// this local copy only decides whether to show the submit form or the
/// "come back later" state without waiting on a round trip first.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/daos/local_settings_dao.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/app_feedback.dart';
import '../../../domain/repositories/feedback_repository.dart';

const _lastSubmittedAtKey = 'lastFeedbackSubmittedAt';
const _reaskCooldown = Duration(hours: 24);

class FeedbackState {
  final List<AppFeedback> feed;
  final bool loadingFeed;

  /// Null until the local timestamp has actually been read from Drift —
  /// distinct from "never submitted", which is `DateTime.fromMillisecondsSinceEpoch(0)`
  /// after that read completes, so the submit form doesn't flash visible
  /// for one frame on every cold start before the real value loads.
  final DateTime? lastSubmittedAt;

  final bool submitting;

  /// Set only by a failed [FeedbackController.loadFeed]/`submit` call —
  /// a student-safe message, never a raw exception.
  final String? error;

  const FeedbackState({
    this.feed = const [],
    this.loadingFeed = true,
    this.lastSubmittedAt,
    this.submitting = false,
    this.error,
  });

  bool get canSubmitNow {
    final last = lastSubmittedAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= _reaskCooldown;
  }

  Duration? get timeUntilNextSubmission {
    final last = lastSubmittedAt;
    if (last == null) return null;
    final remaining = _reaskCooldown - DateTime.now().difference(last);
    return remaining.isNegative ? null : remaining;
  }

  FeedbackState copyWith({
    List<AppFeedback>? feed,
    bool? loadingFeed,
    DateTime? lastSubmittedAt,
    bool? submitting,
    String? error,
  }) =>
      FeedbackState(
        feed: feed ?? this.feed,
        loadingFeed: loadingFeed ?? this.loadingFeed,
        lastSubmittedAt: lastSubmittedAt ?? this.lastSubmittedAt,
        submitting: submitting ?? this.submitting,
        error: error,
      );
}

class FeedbackController extends StateNotifier<FeedbackState> {
  final FeedbackRepository? _repository;
  final LocalSettingsDao? _settings;

  FeedbackController(this._repository, this._settings) : super(const FeedbackState()) {
    unawaited(_loadLastSubmittedAt());
    unawaited(loadFeed());
  }

  Future<void> _loadLastSubmittedAt() async {
    final stored = await _settings?.get(_lastSubmittedAtKey);
    final parsed = stored == null ? null : DateTime.tryParse(stored);
    state = state.copyWith(lastSubmittedAt: parsed ?? DateTime.fromMillisecondsSinceEpoch(0));
  }

  Future<void> loadFeed() async {
    final repo = _repository;
    if (repo == null) {
      state = state.copyWith(loadingFeed: false, error: "Couldn't reach the server. Check your connection.");
      return;
    }
    state = state.copyWith(loadingFeed: true, error: null);
    try {
      final feed = await repo.loadFeed();
      state = state.copyWith(feed: feed, loadingFeed: false);
    } catch (_) {
      state = state.copyWith(
        loadingFeed: false,
        error: "Couldn't load feedback. Check your connection and try again.",
      );
    }
  }

  /// Returns `true` on success. A caller that gets `false` should read
  /// [FeedbackState.error] for what to show.
  Future<bool> submit({
    required int rating,
    required String comment,
    required bool showName,
    required String? localFullName,
  }) async {
    final repo = _repository;
    if (repo == null) {
      state = state.copyWith(error: "Couldn't reach the server. Check your connection and try again.");
      return false;
    }
    state = state.copyWith(submitting: true, error: null);
    try {
      await repo.submit(
        rating: rating,
        comment: comment.trim(),
        displayName: showName ? localFullName : null,
      );
      final now = DateTime.now();
      state = state.copyWith(submitting: false, lastSubmittedAt: now);
      await _settings?.set(_lastSubmittedAtKey, now.toIso8601String());
      unawaited(loadFeed());
      return true;
    } on FeedbackRateLimitedException {
      // The client-side cooldown already hides the form in this case, so
      // reaching this means a different device was used to submit more
      // recently than this one's local record shows -- sync the local
      // clock to "now" so the form stays hidden consistently from here.
      final now = DateTime.now();
      state = state.copyWith(
        submitting: false,
        lastSubmittedAt: now,
        error: "You've already shared feedback in the last 24 hours.",
      );
      await _settings?.set(_lastSubmittedAtKey, now.toIso8601String());
      return false;
    } catch (_) {
      state = state.copyWith(
        submitting: false,
        error: "Couldn't submit your feedback. Check your connection and try again.",
      );
      return false;
    }
  }
}

final feedbackControllerProvider = StateNotifierProvider<FeedbackController, FeedbackState>(
  (ref) => FeedbackController(
    ref.watch(feedbackRepositoryProvider),
    ref.watch(localSettingsDaoProvider),
  ),
);

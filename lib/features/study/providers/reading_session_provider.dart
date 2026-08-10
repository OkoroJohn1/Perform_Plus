/// Reading timer + streak — the only Study-tab slice in scope for V1 (see
/// AGENTS.md roadmap: "reading timer + streak" under V1, everything else in
/// Study is V2).
///
/// TODO(v1): persist streak/session history once Drift lands. In-memory
/// only for now, resets on app restart — same posture as every other
/// provider in the app pre-Drift.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A session must reach this length to count toward the streak — guards
/// against a stray tap inflating the streak with a zero-effort "session".
const _minSessionForStreak = Duration(minutes: 5);

class ReadingStreakState {
  final Duration todayElapsed;
  final int currentStreakDays;
  final DateTime? lastSessionDate;
  final bool isRunning;

  const ReadingStreakState({
    this.todayElapsed = Duration.zero,
    this.currentStreakDays = 0,
    this.lastSessionDate,
    this.isRunning = false,
  });

  ReadingStreakState copyWith({
    Duration? todayElapsed,
    int? currentStreakDays,
    DateTime? lastSessionDate,
    bool? isRunning,
  }) =>
      ReadingStreakState(
        todayElapsed: todayElapsed ?? this.todayElapsed,
        currentStreakDays: currentStreakDays ?? this.currentStreakDays,
        lastSessionDate: lastSessionDate ?? this.lastSessionDate,
        isRunning: isRunning ?? this.isRunning,
      );
}

class ReadingSessionController extends StateNotifier<ReadingStreakState> {
  ReadingSessionController() : super(const ReadingStreakState());

  Timer? _ticker;

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(todayElapsed: state.todayElapsed + const Duration(seconds: 1));
    });
  }

  void pause() {
    _ticker?.cancel();
    _ticker = null;
    if (!state.isRunning) return;
    state = state.copyWith(isRunning: false);
    _maybeExtendStreak();
  }

  void _maybeExtendStreak() {
    if (state.todayElapsed < _minSessionForStreak) return;

    final today = DateTime.now();
    final last = state.lastSessionDate;
    final isNewDay = last == null ||
        last.year != today.year ||
        last.month != today.month ||
        last.day != today.day;
    if (!isNewDay) return;

    final wasYesterday = last != null &&
        today.difference(DateTime(last.year, last.month, last.day)).inDays == 1;

    state = state.copyWith(
      currentStreakDays: wasYesterday ? state.currentStreakDays + 1 : 1,
      lastSessionDate: today,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final readingSessionProvider =
    StateNotifierProvider<ReadingSessionController, ReadingStreakState>(
  (ref) => ReadingSessionController(),
);

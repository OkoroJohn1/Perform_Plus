/// One-time "turn on notifications?" nudge shown on the Dashboard, so the
/// student is asked once (ever) rather than left to discover the daily
/// reminders only if they happen to grant the OS permission some other
/// way. Same "load once, persist a dismissed flag, never nag again" shape
/// as `pin_provider.dart`'s PIN prompt.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/daos/local_settings_dao.dart';
import '../../../data/repositories/repository_providers.dart';

const _notificationPromptDismissedKey = 'notificationPromptDismissed';

class NotificationPromptState {
  final bool loaded;
  final bool dismissed;

  const NotificationPromptState({this.loaded = false, this.dismissed = false});

  NotificationPromptState copyWith({bool? loaded, bool? dismissed}) => NotificationPromptState(
        loaded: loaded ?? this.loaded,
        dismissed: dismissed ?? this.dismissed,
      );
}

class NotificationPromptController extends StateNotifier<NotificationPromptState> {
  final LocalSettingsDao? _dao;

  NotificationPromptController(this._dao) : super(const NotificationPromptState()) {
    unawaited(_load());
  }

  /// Fixed-state constructor for widget tests — no Drift access.
  NotificationPromptController.seeded(super.state) : _dao = null;

  Future<void> _load() async {
    final dismissed = await _dao?.get(_notificationPromptDismissedKey);
    state = state.copyWith(loaded: true, dismissed: dismissed == 'true');
  }

  Future<void> dismiss() async {
    state = state.copyWith(dismissed: true);
    await _dao?.set(_notificationPromptDismissedKey, 'true');
  }
}

final notificationPromptProvider =
    StateNotifierProvider<NotificationPromptController, NotificationPromptState>(
  (ref) => NotificationPromptController(ref.watch(localSettingsDaoProvider)),
);

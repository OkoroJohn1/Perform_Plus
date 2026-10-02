/// The app's light/dark/system theme mode -- the settings screen's
/// "Appearance" row. Persisted to Drift's `local_settings` table
/// (`themeMode` key, value is `ThemeMode.name`) so a choice survives a
/// restart; falls back to `ThemeMode.system` if nothing's been chosen yet
/// or the stored value doesn't parse (e.g. a future enum value on a
/// downgrade).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/daos/local_settings_dao.dart';
import '../../data/repositories/repository_providers.dart';

const _themeModeKey = 'themeMode';

class ThemeModeController extends StateNotifier<ThemeMode> {
  final LocalSettingsDao? _dao;

  ThemeModeController(this._dao) : super(ThemeMode.system) {
    unawaited(_load());
  }

  /// Fixed-state constructor for widget tests -- no Drift access.
  ThemeModeController.seeded(super.state) : _dao = null;

  Future<void> _load() async {
    final stored = await _dao?.get(_themeModeKey);
    if (stored == null) return;
    state = ThemeMode.values.firstWhere((m) => m.name == stored, orElse: () => ThemeMode.system);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _dao?.set(_themeModeKey, mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController(ref.watch(localSettingsDaoProvider)),
);

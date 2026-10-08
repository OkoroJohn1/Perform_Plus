/// The app's accent colour -- the Me tab's "Theme colour" row. Persisted to
/// Drift's `local_settings` table (`themeAccent` key), same mechanism as
/// [ThemeModeController].
///
/// ⚠ Scope note: this recolors `Theme.of(context).colorScheme` app-wide
/// (every generic Material control -- buttons, switches, radios, dialogs --
/// that doesn't set its own explicit colour), the auth/onboarding flow's
/// `ColorScheme`, and every screen written to read this accent directly
/// (the rebuilt Me tab does). It deliberately does NOT retint the ~150
/// places across Dashboard/Academics/Study/Roadmap/Reports that hardcode
/// `OnboardingLightPalette.primary` as a `const Color` literal -- those are
/// genuine compile-time constants baked in by earlier rebuilds, and
/// converting all of them to read a runtime value is a much larger, separate
/// refactor (removing `const` cascades through every enclosing widget that
/// currently relies on it). Retinting them is real follow-up work, not a
/// silent gap.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/daos/local_settings_dao.dart';
import '../../data/repositories/repository_providers.dart';

enum AppAccent { blue, red, green, beige, lightBlue, purple, white }

extension AppAccentColors on AppAccent {
  String get label => switch (this) {
        AppAccent.blue => 'Blue',
        AppAccent.red => 'Red',
        AppAccent.green => 'Green',
        AppAccent.beige => 'Beige',
        AppAccent.lightBlue => 'Light Blue',
        AppAccent.purple => 'Purple',
        AppAccent.white => 'White',
      };

  Color get primary => switch (this) {
        AppAccent.blue => const Color(0xFF5B4BD4),
        AppAccent.red => const Color(0xFFDC2626),
        AppAccent.green => const Color(0xFF16A34A),
        AppAccent.beige => const Color(0xFF9C7A54),
        AppAccent.lightBlue => const Color(0xFF0EA5E9),
        AppAccent.purple => const Color(0xFF9333EA),
        AppAccent.white => const Color(0xFFFFFFFF),
      };

  Color get gradientStart => switch (this) {
        AppAccent.blue => const Color(0xFF6D5CE0),
        AppAccent.red => const Color(0xFFEF4444),
        AppAccent.green => const Color(0xFF22C55E),
        AppAccent.beige => const Color(0xFFB79572),
        AppAccent.lightBlue => const Color(0xFF38BDF8),
        AppAccent.purple => const Color(0xFFA855F7),
        // A hair off pure white at the gradient's own start -- an
        // absolutely flat #FFFFFF-to-#FFFFFF-ish fill reads as "no
        // gradient at all" / a rendering glitch on a white card; this
        // keeps a faint, genuinely white-reading sheen while still being
        // a visible two-stop gradient.
        AppAccent.white => const Color(0xFFFFFFFF),
      };

  Color get gradientEnd => switch (this) {
        AppAccent.blue => const Color(0xFF4A3BC4),
        AppAccent.red => const Color(0xFFB91C1C),
        AppAccent.green => const Color(0xFF15803D),
        AppAccent.beige => const Color(0xFF7A5F3F),
        AppAccent.lightBlue => const Color(0xFF0284C7),
        AppAccent.purple => const Color(0xFF7E22CE),
        AppAccent.white => const Color(0xFFE2E1EC),
      };
}

const _themeAccentKey = 'themeAccent';

class ThemeAccentController extends StateNotifier<AppAccent> {
  final LocalSettingsDao? _dao;

  ThemeAccentController(this._dao) : super(AppAccent.blue) {
    unawaited(_load());
  }

  /// Fixed-state constructor for widget tests -- no Drift access.
  ThemeAccentController.seeded(super.state) : _dao = null;

  Future<void> _load() async {
    final stored = await _dao?.get(_themeAccentKey);
    if (stored == null) return;
    state = AppAccent.values.firstWhere((a) => a.name == stored, orElse: () => AppAccent.blue);
  }

  Future<void> setAccent(AppAccent accent) async {
    state = accent;
    await _dao?.set(_themeAccentKey, accent.name);
  }
}

final themeAccentProvider = StateNotifierProvider<ThemeAccentController, AppAccent>(
  (ref) => ThemeAccentController(ref.watch(localSettingsDaoProvider)),
);

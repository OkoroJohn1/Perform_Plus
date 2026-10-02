/// The theme-aware semantic palette -- the fix for two related problems:
/// Dark mode not visibly changing anything, and the Theme colour picker only
/// affecting the Me tab. Both had the same root cause: almost every screen
/// painted itself from `OnboardingLightPalette`'s `static const Color`
/// values directly, bypassing `Theme.of(context)` entirely, so neither
/// brightness nor the chosen accent ever reached them.
///
/// [AppPalette] is a `ThemeExtension` computed once per (brightness, accent)
/// pair in `AppTheme._build` and read back via `context.palette`. Retrofit
/// priority for this pass was every screen's own Scaffold/background colour,
/// the shared card widgets (`GlassCard`/`GradientScaffold`/`GlassNavBar`),
/// and primary accents -- the layer that makes toggling Dark or the accent
/// picker visibly change the whole app, not just the Me tab. A full sweep of
/// every secondary/tertiary hardcoded text colour inside each screen's body
/// content is real remaining work, tracked in AGENTS.md, not silently
/// dropped.
library;

import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// Outer Scaffold background for every tab screen.
  final Color background;

  /// Card/sheet fill.
  final Color surface;

  /// Hairline border/divider on cards.
  final Color surfaceBorder;

  final Color bodyText;
  final Color secondaryText;
  final Color hintText;
  final Color divider;

  /// The chosen accent colour and its two-stop gradient (Blue/Red/Green/
  /// Beige -- see `theme_accent_provider.dart`).
  final Color primary;
  final Color primaryGradientStart;
  final Color primaryGradientEnd;

  /// Text/icon colour to use ON TOP of [primary] or its gradient -- always
  /// white across all four accents (each is dark/saturated enough), kept as
  /// its own field rather than a hardcoded `Colors.white` at each call site
  /// so a future accent that needed dark-on-light text has one place to fix.
  final Color onPrimary;

  final Color amber;
  final Color amberBackground;
  final Color success;
  final Color error;
  final Color errorBackground;
  final Color emptyIcon;
  final Color disabledFill;
  final Color disabledText;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceBorder,
    required this.bodyText,
    required this.secondaryText,
    required this.hintText,
    required this.divider,
    required this.primary,
    required this.primaryGradientStart,
    required this.primaryGradientEnd,
    required this.onPrimary,
    required this.amber,
    required this.amberBackground,
    required this.success,
    required this.error,
    required this.errorBackground,
    required this.emptyIcon,
    required this.disabledFill,
    required this.disabledText,
  });

  factory AppPalette.resolve({required Brightness brightness, required Color accentPrimary, required Color accentGradientStart, required Color accentGradientEnd}) {
    final isDark = brightness == Brightness.dark;
    return AppPalette(
      background: isDark ? const Color(0xFF0B0A18) : const Color(0xFFF7F7FB),
      surface: isDark ? const Color(0xFF18162C) : Colors.white,
      surfaceBorder: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE5E5EC),
      bodyText: isDark ? Colors.white : const Color(0xFF0F0F14),
      secondaryText: isDark ? Colors.white.withValues(alpha: 0.70) : const Color(0xFF6B7280),
      hintText: isDark ? Colors.white.withValues(alpha: 0.54) : const Color(0xFF9CA3AF),
      divider: isDark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFECECF1),
      primary: accentPrimary,
      primaryGradientStart: accentGradientStart,
      primaryGradientEnd: accentGradientEnd,
      onPrimary: Colors.white,
      amber: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
      amberBackground: isDark ? const Color(0x26FBBF24) : const Color(0x14B45309),
      success: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
      error: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
      errorBackground: isDark ? const Color(0x26F87171) : const Color(0x14DC2626),
      emptyIcon: isDark ? Colors.white.withValues(alpha: 0.30) : const Color(0xFFD1D5DB),
      disabledFill: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE5E5EC),
      disabledText: isDark ? Colors.white.withValues(alpha: 0.38) : const Color(0xFF9CA3AF),
    );
  }

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceBorder,
    Color? bodyText,
    Color? secondaryText,
    Color? hintText,
    Color? divider,
    Color? primary,
    Color? primaryGradientStart,
    Color? primaryGradientEnd,
    Color? onPrimary,
    Color? amber,
    Color? amberBackground,
    Color? success,
    Color? error,
    Color? errorBackground,
    Color? emptyIcon,
    Color? disabledFill,
    Color? disabledText,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      bodyText: bodyText ?? this.bodyText,
      secondaryText: secondaryText ?? this.secondaryText,
      hintText: hintText ?? this.hintText,
      divider: divider ?? this.divider,
      primary: primary ?? this.primary,
      primaryGradientStart: primaryGradientStart ?? this.primaryGradientStart,
      primaryGradientEnd: primaryGradientEnd ?? this.primaryGradientEnd,
      onPrimary: onPrimary ?? this.onPrimary,
      amber: amber ?? this.amber,
      amberBackground: amberBackground ?? this.amberBackground,
      success: success ?? this.success,
      error: error ?? this.error,
      errorBackground: errorBackground ?? this.errorBackground,
      emptyIcon: emptyIcon ?? this.emptyIcon,
      disabledFill: disabledFill ?? this.disabledFill,
      disabledText: disabledText ?? this.disabledText,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      bodyText: Color.lerp(bodyText, other.bodyText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      hintText: Color.lerp(hintText, other.hintText, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryGradientStart: Color.lerp(primaryGradientStart, other.primaryGradientStart, t)!,
      primaryGradientEnd: Color.lerp(primaryGradientEnd, other.primaryGradientEnd, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberBackground: Color.lerp(amberBackground, other.amberBackground, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorBackground: Color.lerp(errorBackground, other.errorBackground, t)!,
      emptyIcon: Color.lerp(emptyIcon, other.emptyIcon, t)!,
      disabledFill: Color.lerp(disabledFill, other.disabledFill, t)!,
      disabledText: Color.lerp(disabledText, other.disabledText, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Falls back to a palette derived from the ambient `ThemeData` when no
  /// [AppPalette] extension is registered -- e.g. a widget test that builds
  /// a bare `MaterialApp`/`MaterialApp.router` without going through
  /// `AppTheme.light`/`.dark`. Every real app screen gets the real one
  /// (registered in `AppTheme._build`/`onboardingLightWithAccent`); this
  /// just keeps an un-themed test harness from crashing on a null check.
  AppPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ??
        AppPalette.resolve(
          brightness: theme.brightness,
          accentPrimary: theme.colorScheme.primary,
          accentGradientStart: theme.colorScheme.primary,
          accentGradientEnd: theme.colorScheme.primary,
        );
  }
}

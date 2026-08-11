import 'package:flutter/material.dart';

/// Theme.
///
/// Every screen now sits on [GradientScaffold]'s permanent dark blue-black
/// gradient (see `shared/widgets/gradient_scaffold.dart`) with
/// [GlassCard]/[GradientButton] surfaces on top — there is no flat light
/// background left in the app. `AppTheme.light` and `AppTheme.dark` both
/// resolve to the same dark-appropriate `ColorScheme`/text colors so text
/// stays legible regardless of the system/user theme-mode setting; the
/// distinction is kept only so the Me tab's dark-mode toggle has something
/// to point at if a genuinely different second look is added later.
class AppTheme {
  const AppTheme._();

  static const seed = Color(0xFF5B4BD4);

  static ThemeData get light => _build();
  static ThemeData get dark => _build();

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: Typography.whiteMountainView.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        indicatorColor: scheme.primary.withValues(alpha: 0.4),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: Colors.white, fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: Colors.white),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Theme.
///
/// One seed colour drives both modes. Your three mockup variants
/// (purple/blue, green, red) are one constant change away from each other —
/// swap [seed] to try a direction rather than rebuilding the board.
///
/// A note on the red variant: red carries error/danger semantics in every
/// UI convention. On a screen that tells a student their CGPA fell short of
/// a goal, a red-primary interface makes an already difficult moment feel
/// like a system failure. Green and purple both leave red free to mean
/// "something is wrong", which you will want.
class AppTheme {
  const AppTheme._();

  static const seed = Color(0xFF5B4BD4);

  /// The mockup's screens sit on a faint lavender tint, not flat white —
  /// cards read as distinct surfaces against it without needing shadows.
  static const _lightBackground = Color(0xFFF8F7FD);
  static const _darkBackground = Color(0xFF14102B);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final background =
        brightness == Brightness.light ? _lightBackground : _darkBackground;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        isDense: true,
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
        color: brightness == Brightness.light ? Colors.white : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

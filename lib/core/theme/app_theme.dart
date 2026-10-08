import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';
import 'theme_accent_provider.dart';

/// Theme.
///
/// `AppTheme.light`/`dark` are the root `MaterialApp.router` theme/darkTheme,
/// genuinely distinct now (see [_build]'s doc note) and re-seeded from the
/// Me tab's accent-colour choice (`theme_accent_provider.dart`). Most of the
/// app's own tabs (Dashboard/Academics/Study/AI) still paint themselves from
/// hardcoded `OnboardingLightPalette`/`DashboardPalette` constants rather
/// than reading `Theme.of(context)` -- these two `ThemeData`s mainly govern
/// generic Material controls (dialogs, snackbars, unstyled buttons) plus the
/// pre-tab-shell auth/onboarding flow and the Me tab, which reads the accent
/// directly.
class AppTheme {
  const AppTheme._();

  static const seed = Color(0xFF5B4BD4);

  /// ⚠ Previously both `light` and `dark` called `_build()` with
  /// `Brightness.dark` hardcoded regardless of which was asked for -- a
  /// leftover from when the whole app was permanently dark-themed and the
  /// distinction was cosmetic. Now that `MaterialApp.router` actually
  /// switches between them via `themeMode`, they need to genuinely differ.
  static ThemeData light({AppAccent accent = AppAccent.blue}) =>
      _build(brightness: Brightness.light, accent: accent);
  static ThemeData dark({AppAccent accent = AppAccent.blue}) =>
      _build(brightness: Brightness.dark, accent: accent);

  /// The light-mode `ThemeData` for the pre-tab-shell auth/onboarding flow
  /// (sign-in, profile setup, add-results, backfill, goal setting,
  /// institution setup, GPA reveal) — see [OnboardingLightPalette]. Always
  /// Blue: a student hasn't reached the Me tab's theme-colour picker yet by
  /// the time they're in this flow, so there's no chosen accent to apply.
  static ThemeData get onboardingLight => onboardingLightWithAccent(OnboardingLightPalette.primary);

  static ThemeData onboardingLightWithAccent(Color accent) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        extensions: [
          AppPalette.resolve(
            brightness: Brightness.light,
            accentPrimary: accent,
            accentGradientStart: AppAccent.blue.gradientStart,
            accentGradientEnd: AppAccent.blue.gradientEnd,
          ),
        ],
        scaffoldBackgroundColor: OnboardingLightPalette.background,
        // Plus Jakarta Sans everywhere: nearly every screen's Text widgets
        // set fontSize/fontWeight/color directly rather than reading
        // Theme.textTheme, but Flutter's Text.build() still merges an
        // explicit TextStyle onto the ambient DefaultTextStyle for any
        // field it doesn't set itself -- fontFamily included -- so this one
        // change cascades to those hardcoded styles without touching them.
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData(brightness: Brightness.light).textTheme,
        ).apply(bodyColor: OnboardingLightPalette.bodyText, displayColor: OnboardingLightPalette.bodyText),
        colorScheme: ColorScheme.light(
          primary: accent,
          onPrimary: Colors.white,
          secondary: accent,
          onSecondary: Colors.white,
          surface: OnboardingLightPalette.background,
          onSurface: OnboardingLightPalette.bodyText,
          onSurfaceVariant: OnboardingLightPalette.secondaryText,
          outlineVariant: OnboardingLightPalette.divider,
          error: OnboardingLightPalette.error,
        ),
      );

  static ThemeData _build({required Brightness brightness, required AppAccent accent}) {
    final isDark = brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : OnboardingLightPalette.bodyText;
    final surfaceTint = isDark ? Colors.white : Colors.black;
    final baseTypography = isDark ? Typography.whiteMountainView : Typography.blackMountainView;
    final palette = AppPalette.resolve(
      brightness: brightness,
      accentPrimary: accent.primary,
      accentGradientStart: accent.gradientStart,
      accentGradientEnd: accent.gradientEnd,
    );
    // `ColorScheme.fromSeed` derives every role from the seed's HCT hue --
    // fine for a saturated accent, but a zero-chroma seed (White) has no
    // real hue to derive from, and Material's algorithm falls back to an
    // arbitrary default hue (a pale blue) for `primary`/`secondary`. Every
    // *generic* Material control (Switch, Checkbox, RadioListTile, the
    // default FAB, ...) reads those roles straight off this ambient
    // ColorScheme, as do several screens' own `Theme.of(context)
    // .colorScheme.primary` reads (see `me_shell.dart`) -- both would
    // silently show that fallback blue instead of the White accent the
    // student actually picked. Overriding the roles this app actually
    // touches with the same contrast-safe values `AppPalette` already
    // computes keeps every reader of either API in agreement, for every
    // accent, not only the saturated ones where the seed algorithm
    // happens to land close to the original colour anyway.
    final scheme = ColorScheme.fromSeed(
      seedColor: accent.primary,
      brightness: brightness,
    ).copyWith(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [palette],
      scaffoldBackgroundColor: palette.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTypography).apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        isDense: true,
        filled: true,
        fillColor: surfaceTint.withValues(alpha: isDark ? 0.06 : 0.04),
        labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.7)),
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
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: surfaceTint.withValues(alpha: isDark ? 0.16 : 0.08)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceTint.withValues(alpha: isDark ? 0.06 : 0.04),
        indicatorColor: scheme.primary.withValues(alpha: 0.4),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: onSurface, fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.all(
          IconThemeData(color: onSurface),
        ),
      ),
    );
  }
}

/// Colours for `features/onboarding/screens/splash_screen.dart` only.
///
/// The splash is deliberately the one screen with its own fixed dark
/// palette, independent of [AppTheme]/[ColorScheme] — every other screen
/// must keep using `Theme.of(context).colorScheme`. Do not reuse these
/// constants outside the splash screen.
class SplashPalette {
  const SplashPalette._();

  /// Base background — near-black with a purple bias, not neutral grey.
  static const background = Color(0xFF0A0518);

  /// Centre colour of the subtle radial lift behind the logo cluster.
  static const backgroundGlow = Color(0xFF150A2E);

  /// "Perform" wordmark — flat white, no gradient.
  static const wordmark = Color(0xFFFFFFFF);

  /// Horizontal gradient across the wordmark's "+" glyph only.
  static const plusGradientStart = Color(0xFF22D3EE);
  static const plusGradientEnd = Color(0xFFA855F7);

  /// Tagline copy colour.
  static const tagline = Color(0xFFE8E8F0);

  /// Tagline separator dots (rendered as circles, never the "•" glyph).
  static const taglineDot = Color(0xFFA855F7);

  /// Wave field ribbon gradient, left to right.
  static const waveDeepBlue = Color(0xFF1D4ED8);
  static const waveBlue = Color(0xFF3B82F6);
  static const wavePurple = Color(0xFF7C3AED);
  static const waveViolet = Color(0xFFA855F7);
  static const waveMagenta = Color(0xFFD946EF);

  /// Version stamp text.
  static const versionText = Color(0xFF9CA3AF);

  /// Surface colour of the (light-themed) screen splash hands off to — the
  /// background lightens toward this in the final transition-out frames
  /// instead of hard-cutting to it.
  static const destinationSurface = Color(0xFFFFFFFF);
}

/// Colours for the light-theme half of the app — the onboarding screens
/// that adopt it (institution setup, add-results) rather than the rest of
/// the app's permanent dark gradient.
///
/// [AppTheme.onboardingLight] wires [primary]/[background]/[bodyText]/
/// [secondaryText]/[divider] into a real `ColorScheme` so widgets read them
/// via `Theme.of(context).colorScheme` rather than this class directly; the
/// remaining constants here (avatar palette, amber warning, success,
/// disabled/hint greys) have no natural `ColorScheme` slot and are read
/// from this class directly. Do not reuse these outside a screen that
/// adopts the same light treatment.
class OnboardingLightPalette {
  const OnboardingLightPalette._();

  static const background = Color(0xFFFFFFFF);
  static const primary = Color(0xFF5B4BD4);
  static const primaryGradientStart = Color(0xFF6D5CE0);
  static const bodyText = Color(0xFF0F0F14);
  static const secondaryText = Color(0xFF6B7280);
  static const divider = Color(0xFFECECF1);

  static const searchBorder = Color(0xFFE5E5EC);
  static const hintText = Color(0xFF9CA3AF);

  static const disabledFill = Color(0xFFE5E5EC);
  static const disabledText = Color(0xFF9CA3AF);

  static const emptyIcon = Color(0xFFD1D5DB);

  /// Fill for the goal-setting screen's "current standing" block.
  static const standingFill = Color(0xFFF5F5F9);

  /// Verified-with-AA-in-mind: #B45309 text/icon over an 8%-alpha tint of
  /// itself on a white surface computes to a ~4.5:1 contrast ratio, the AA
  /// floor for normal-size text. Do not lighten the background tint further.
  static const amber = Color(0xFFB45309);
  static const amberBackground = Color(0x14B45309);

  /// Extraction-success checkmark on the add-results screen.
  static const success = Color(0xFF16A34A);

  /// Field/form validation errors on the auth screen.
  static const error = Color(0xFFDC2626);
  static const errorBackground = Color(0x14DC2626);

  /// Field labels on the profile-setup screen — distinct from
  /// [secondaryText], and doubles as the empty-avatar camera badge fill.
  static const labelText = Color(0xFF4B5563);

  /// Empty profile-photo avatar: circle fill and head/shoulders silhouette.
  static const avatarEmptyFill = Color(0xFFE8E8EC);
  static const avatarSilhouette = Color(0xFFC4C4CC);

  /// Stable per-institution avatar colours, cycled in seed-list order by
  /// `Institution.avatarColorIndex` — see `LettermarkAvatar`.
  static const avatarPalette = <Color>[
    Color(0xFF1E5C3A), // green
    Color(0xFF7B1E1E), // maroon
    Color(0xFF1E3A8A), // navy
    Color(0xFFB45309), // amber
    Color(0xFF5B21B6), // violet
    Color(0xFF0F766E), // teal
    Color(0xFF9F1239), // rose
    Color(0xFF3F6212), // olive
  ];
}

/// Colours for the six `Feasibility` states on the goal-setting screen.
/// `secured` and `comfortable` deliberately share a colour (green) — the
/// spec's own six-state design groups them, distinguishing only by icon
/// and copy. `unreachable` is grey, NOT red: it's a fact about arithmetic
/// the student didn't get wrong, not an error state.
///
/// Amber and burnt-orange are the two pairings AA contrast was actually
/// checked on (title text at full strength over the card's own tinted
/// background): amber computes to ~4.5:1 (the AA floor, so don't lighten
/// its surface tint further) and burnt orange to ~4.6:1. Both pass but
/// amber has essentially no margin.
class FeasibilityPalette {
  const FeasibilityPalette._();

  static const secured = Color(0xFF16A34A);
  static const withinReach = Color(0xFF5B4BD4);
  static const demanding = Color(0xFFB45309);
  static const extremelyDemanding = Color(0xFFC2410C);
  static const unreachable = Color(0xFF6B7280);
}

/// Colours specific to the GPA reveal screen's hero gauge and confetti.
/// Everything else on that screen (classification-by-band-position, the
/// stat row, the excluded-results block) reuses [OnboardingLightPalette]
/// constants directly — first band green is [OnboardingLightPalette.success],
/// second is [OnboardingLightPalette.primary], third is
/// [OnboardingLightPalette.amber], anything below is
/// [OnboardingLightPalette.secondaryText].
class GpaRevealPalette {
  const GpaRevealPalette._();

  /// Hero card vertical gradient, top colour (bottom is plain white).
  static const heroGradientTop = Color(0xFFF4F2FE);

  /// Gauge fill `SweepGradient`, light-to-dark across the swept arc.
  /// [OnboardingLightPalette.primary] sits in the middle of this range.
  static const gaugeGradientLight = Color(0xFF7C6FE8);
  static const gaugeGradientDark = Color(0xFF4A3BC4);

  /// Confetti-only accent colour — distinct from
  /// [OnboardingLightPalette.amber], which is reserved for warnings/excluded
  /// rows and reads as muted rather than celebratory.
  static const confettiAmber = Color(0xFFF59E0B);
}

/// Colours specific to the dashboard (Home tab) — the one screen with its
/// own tinted `#F7F7FB` scaffold rather than the app's dark gradient or the
/// onboarding flat white, so white cards lift off it.
///
/// Classification-band-position colours (used behind the trend chart and
/// on the semester-comparison bars) deliberately reuse the same four-tier
/// mapping as the GPA reveal screen's pill — see [GpaRevealPalette] doc —
/// via [colorForBandIndex], rather than duplicating the hexes here.
class DashboardPalette {
  const DashboardPalette._();

  static const scaffoldBackground = Color(0xFFF7F7FB);

  /// Hero card diagonal gradient, top-left to bottom-right.
  static const heroGradientStart = OnboardingLightPalette.primaryGradientStart;
  static const heroGradientEnd = GpaRevealPalette.gaugeGradientDark;

  /// Goal-progress-ring fill colours, one per [Feasibility] state — distinct
  /// from [FeasibilityPalette], which is tuned for text/icons on a white
  /// card. These sit on the hero's dark gradient fill instead, so they read
  /// as pale, glowing accents rather than the saturated on-white versions.
  static const ringSecured = Color(0xFF4ADE80);
  static const ringWithinReach = Color(0xFFA5B4FC);
  static const ringDemanding = Color(0xFFFCD34D);
  static const ringExtremelyDemanding = Color(0xFFFDBA74);

  /// Semester-comparison bar track.
  static const barTrack = Color(0xFFF0F0F5);
}

/// The classification-band colour system — used on the GPA reveal pill,
/// the dashboard's trend chart/semester bars, and the Academics standing
/// card/semester list. Defined once here rather than per-screen so all
/// three can never disagree with each other on what a colour means.
///
/// Two related but distinct mappings live here:
///   * [colorForBandIndex] — by a band's RANK among the scheme's own
///     classifications (0 = top band, 1 = second, ...), used wherever a
///     CGPA or semester GPA has already been classified via
///     `GradingScheme.classify`.
///   * [forGradeLetter] — by the literal letter grade earned in a single
///     course (A/B/C/D-E/F), used for credit-load splits, which group raw
///     course results rather than a classified average.
/// They happen to share the same five colours in the same order because
/// FUTO's standard scale lines up letter-for-band, but they answer
/// different questions and a scheme where they diverge should still use
/// the correct one for what it's actually describing.
class ClassificationPalette {
  const ClassificationPalette._();

  static Color colorForBandIndex(int index) => switch (index) {
        0 => OnboardingLightPalette.success,
        1 => OnboardingLightPalette.primary,
        2 => OnboardingLightPalette.amber,
        _ => OnboardingLightPalette.secondaryText,
      };

  static const gradeA = OnboardingLightPalette.success;
  static const gradeB = OnboardingLightPalette.primary;
  static const gradeC = GpaRevealPalette.gaugeGradientLight;
  static const gradeBelow = OnboardingLightPalette.amber; // D/E
  static const gradeFailed = OnboardingLightPalette.error; // F

  /// Letters outside FUTO's standard A-F scale fall into
  /// [OnboardingLightPalette.secondaryText] rather than being silently
  /// mis-bucketed into one of the five real categories.
  static Color forGradeLetter(String letter) => switch (letter.trim().toUpperCase()) {
        'A' => gradeA,
        'B' => gradeB,
        'C' => gradeC,
        'D' || 'E' => gradeBelow,
        'F' => gradeFailed,
        _ => OnboardingLightPalette.secondaryText,
      };
}

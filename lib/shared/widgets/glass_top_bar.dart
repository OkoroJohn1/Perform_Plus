/// The background behind every tab's top bar (Dashboard/Academics/AI/
/// Study/Me/Notifications). Previously every one of these painted itself
/// with a hardcoded light fill (`DashboardPalette.scaffoldBackground`) that
/// never changed for dark mode, while the title/icons on top of it DID
/// switch to `context.palette.bodyText` (white) — so dark mode rendered
/// white text on a white bar, invisible. Flat and matching the page behind
/// it in light mode; in dark mode a slim frosted-glass gradient of the
/// chosen theme accent, dark enough that the now-white text stays legible.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class TopBarGlassBackground extends StatelessWidget {
  final Widget child;

  const TopBarGlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;

    if (!isDark) {
      return Container(color: palette.background, child: child);
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.primaryGradientStart.withValues(alpha: 0.30),
                palette.primaryGradientEnd.withValues(alpha: 0.22),
                Colors.black.withValues(alpha: 0.22),
              ],
            ),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
          ),
          child: child,
        ),
      ),
    );
  }
}

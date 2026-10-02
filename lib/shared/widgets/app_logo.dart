/// The official Perform+ mark — the "P" glyph alone, transparent background
/// (`assets/images/logo.png`), used everywhere the app shows its brand
/// identity. Screens that also need the "Perform+" wordmark (the splash
/// screen) render that separately as text, since it isn't baked into this
/// asset.
library;

import 'package:flutter/material.dart';

/// Aspect ratio of the source asset — used so callers can size by width
/// alone and get a correctly proportioned mark.
const double _logoAspectRatio = 785 / 861;

class AppLogo extends StatelessWidget {
  /// Rendered width. Height follows the source asset's aspect ratio.
  final double size;

  const AppLogo({super.key, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size / _logoAspectRatio,
      fit: BoxFit.contain,
    );
  }
}

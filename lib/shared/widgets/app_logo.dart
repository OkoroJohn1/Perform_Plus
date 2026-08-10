/// The official Perform+ mark — icon + "Perform+" wordmark baked into one
/// asset (`assets/images/logo.png`), glow and all. Used everywhere the app
/// shows its brand identity.
library;

import 'package:flutter/material.dart';

/// Aspect ratio of the source asset (1536x1024) — used so callers can size
/// by width alone and get a correctly proportioned mark.
const double _logoAspectRatio = 1536 / 1024;

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

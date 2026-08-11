/// Drop-in `Card` replacement with a frosted-glass look — `ClipRRect` +
/// `BackdropFilter` blur + a translucent fill, meant to sit on top of
/// [GradientScaffold]'s dark gradient (glass only reads as "glass" over a
/// colorful backdrop, not flat white). Every `Card(...)` in the app should
/// use this instead.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;

  /// Optional tint (e.g. a warning/error color) blended into the glass
  /// fill — mirrors `Card(color: ...)` usages for warning/insight cards.
  final Color? tint;

  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.tint,
    this.blurSigma = 18,
  });

  @override
  Widget build(BuildContext context) {
    final fill = tint != null
        ? tint!.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.08);

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: borderRadius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Material(
              // Descendants like ListTile/InkWell need a Material ancestor
              // for ink splashes — Container alone won't provide one.
              type: MaterialType.transparency,
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: Colors.white),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

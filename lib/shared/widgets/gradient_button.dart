/// Drop-in `FilledButton`/`FilledButton.icon` replacement — an accent
/// gradient pill instead of a flat fill. `ButtonStyle.backgroundColor` can
/// only express a solid color, so a real gradient needs a custom widget:
/// `Ink` (for the gradient + ripple splash) wrapping an `InkWell`. The
/// gradient tracks the current theme accent (`context.palette`) rather than
/// a fixed colour, so it moves with the Me tab's Theme colour picker.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget label;

  const GradientButton({
    super.key,
    required this.onPressed,
    required Widget child,
  })  : icon = null,
        label = child;

  const GradientButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final palette = context.palette;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [palette.primaryGradientStart, palette.primaryGradientEnd],
    );
    final content = icon == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [icon!, const SizedBox(width: 8), label],
          );

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                child: IconTheme.merge(
                  data: const IconThemeData(color: Colors.white),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

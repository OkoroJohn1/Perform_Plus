/// Drop-in `FilledButton`/`FilledButton.icon` replacement — a blue-to-black
/// gradient pill instead of a flat fill. `ButtonStyle.backgroundColor` can
/// only express a solid color, so a real gradient needs a custom widget:
/// `Ink` (for the gradient + ripple splash) wrapping an `InkWell`.
library;

import 'package:flutter/material.dart';

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

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B7DF0), Color(0xFF0B0A18)],
  );

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
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

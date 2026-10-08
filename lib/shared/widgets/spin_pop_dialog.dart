/// Shared "tap a dashboard chart to see its full-screen breakdown"
/// interaction -- the CGPA trend card and the Performance View (3D bar)
/// card both open this way, so the motion (spin + pop from the centre,
/// background blurred) lives in one place rather than drifting apart
/// across two copies.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

Future<void> showSpinPopDetail(BuildContext context, {required WidgetBuilder builder}) {
  return showGeneralDialog(
    context: context,
    barrierLabel: 'Chart detail',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (context, _, __) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.55)),
        child: RotationTransition(
          turns: Tween(begin: -0.08, end: 0.0).animate(curved),
          child: ScaleTransition(
            scale: Tween(begin: 0.55, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// The blurred, dismiss-on-tap scrim behind every spin-pop detail panel.
class SpinPopScrim extends StatelessWidget {
  const SpinPopScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: ColoredBox(color: Colors.black.withValues(alpha: 0.38)),
      ),
    );
  }
}

/// Wraps a card's chart body so the WHOLE area opens [onTap] on a genuine
/// tap, but never on a drag/slide across it -- and so a tap anywhere on
/// the chart works, not just its margins. A plain `InkWell`/`GestureDetector`
/// wrapping a chart that has its OWN touch handling (fl_chart's
/// `lineTouchData`) sits in the same gesture arena as that inner handling,
/// which can let a slide-to-inspect drag also resolve as this widget's own
/// tap. Putting a dedicated, opaque, tap-only `GestureDetector` as the
/// TOPMOST layer in a `Stack` means it is hit-tested first and intercepts
/// the pointer before the chart beneath it ever sees it -- so the chart's
/// own drag handling can no longer fire at all (fine here: every chart this
/// wraps already force-shows its tooltips regardless of touch), and only a
/// tap (no meaningful movement) ever triggers [onTap].
class TapToExpand extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const TapToExpand({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

/// The global chat entry point — a floating action button shown on Home,
/// Academics and Study (never the AI tab itself, and never Me, which has
/// nothing to advise on; see [AppScaffold]'s `showAdvisorFab`).
///
/// Shrinks to a 40dp icon-only circle on scroll-down and expands back to
/// 56dp on scroll-up, so it never permanently covers a row the student is
/// reading — [AppScaffold] drives [expanded] from its own scroll listener.
///
/// Freely draggable: [onDragUpdate]/[onDragEnd] are optional so this widget
/// stays usable standalone (e.g. a future non-draggable placement) — when
/// [AppScaffold] supplies them, they're wired into this SAME
/// `GestureDetector` rather than a second one wrapping it. A pan and a tap
/// recognizer coexist fine on one `GestureDetector` (Flutter's gesture
/// arena disambiguates by movement); stacking a second detector around
/// this one to add dragging risks it capturing the arena before the tap
/// (opening the chat sheet) ever gets a chance to win.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../features/ai/screens/advisor_chat_sheet.dart';
import 'advisor_mark.dart';

class AdvisorFab extends StatefulWidget {
  final bool expanded;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  const AdvisorFab({
    super.key,
    required this.expanded,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  State<AdvisorFab> createState() => _AdvisorFabState();
}

class _AdvisorFabState extends State<AdvisorFab> {
  bool _pressed = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.expanded ? 56.0 : 40.0;
    final palette = context.palette;

    return GestureDetector(
      key: const ValueKey('advisorFabTap'),
      onTap: () => showAdvisorChatSheet(context),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onPanStart: widget.onDragUpdate == null ? null : (_) => setState(() => _dragging = true),
      onPanUpdate: widget.onDragUpdate,
      onPanEnd: (details) {
        setState(() => _dragging = false);
        widget.onDragEnd?.call(details);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _dragging ? 1.08 : (_pressed ? 0.92 : 1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.primaryGradientStart, palette.primary],
            ),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: _dragging ? 0.42 : 0.30),
                blurRadius: _dragging ? 22 : 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          child: const AdvisorMark(size: 28, simplified: true, color: Colors.white),
        ),
      ),
    );
  }
}

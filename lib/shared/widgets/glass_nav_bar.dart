/// The bottom tab bar — a floating, fully-rounded frosted-glass card rather
/// than an edge-to-edge bar, with margin on every side so it visibly floats
/// above whatever content scrolls underneath it. The gradient beneath the
/// blur is deliberately semi-transparent, not opaque: an opaque fill defeats
/// the point of `BackdropFilter` entirely, since there'd be nothing visible
/// left to blur. The tint sweeps a wide, clearly visible arc on a continuous
/// loop -- an animated-gradient stand-in for a literal video background (no
/// video asset exists, and one would cost real APK size and battery for a
/// bottom bar) -- and is "reactive" in a second, input-driven sense too: the
/// sweep's centre eases toward whichever tab is selected on top of its own
/// ambient drift, so switching tabs visibly nudges the gradient rather than
/// leaving it indifferent to selection. Every colour here comes from
/// `context.palette`, so it already follows both dark/light mode and the
/// Theme colour accent picker -- nothing in this file is hardcoded.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class GlassNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const GlassNavBar({super.key, required this.selectedIndex, required this.onDestinationSelected});

  static const _items = <({IconData filled, IconData outline, String label})>[
    (filled: Icons.home_rounded, outline: Icons.home_outlined, label: 'Home'),
    (filled: Icons.school_rounded, outline: Icons.school_outlined, label: 'Academics'),
    (filled: Icons.auto_awesome_rounded, outline: Icons.auto_awesome_outlined, label: 'Advisor'),
    (filled: Icons.menu_book_rounded, outline: Icons.menu_book_outlined, label: 'Study'),
    (filled: Icons.feedback_rounded, outline: Icons.feedback_outlined, label: 'Feedback'),
    (filled: Icons.person_rounded, outline: Icons.person_outline_rounded, label: 'Me'),
  ];

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar> with TickerProviderStateMixin {
  static const _normalPeriod = Duration(seconds: 7);
  static const _hoverPeriod = Duration(milliseconds: 900);

  late final AnimationController _drift;

  /// Drives the "reactive" half of the gradient -- a short ease from the
  /// previously-selected tab's horizontal position to the newly-selected
  /// one, layered additively on top of `_drift`'s ambient sweep. Separate
  /// controller from `_drift` so switching tabs doesn't reset or stutter
  /// the ambient animation's own phase.
  late final AnimationController _react;
  double _reactFromT = 0;
  double _reactToT = 0;

  double _targetTFor(int index) {
    final last = GlassNavBar._items.length - 1;
    if (last <= 0) return 0;
    // Maps tab index 0..last to roughly -1..1, matching the ambient
    // sweep's own alignment range.
    return (index / last) * 2 - 1;
  }

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: _normalPeriod);
    _react = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _reactFromT = _targetTFor(widget.selectedIndex);
    _reactToT = _reactFromT;
  }

  @override
  void didUpdateWidget(GlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _reactFromT = _targetTFor(oldWidget.selectedIndex);
      _reactToT = _targetTFor(widget.selectedIndex);
      if (MediaQuery.disableAnimationsOf(context)) {
        _react.value = 1;
      } else {
        _react.forward(from: 0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    _react.dispose();
    super.dispose();
  }

  // Desktop/web only -- touch devices never fire hover. Re-calling repeat()
  // with a shorter period picks up from the controller's current value
  // rather than resetting to 0, so the sweep doesn't visibly jump.
  void _setHovered(bool hovered) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _drift.repeat(reverse: true, period: hovered ? _hoverPeriod : _normalPeriod);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Tracks the Me tab's Theme colour choice -- a darker third stop is
    // derived rather than hardcoded so every accent gets the same richness
    // the original purple-only version had.
    final palette = context.palette;
    final gradStart = palette.primaryGradientStart;
    final gradEnd = palette.primaryGradientEnd;
    final gradDeep = Color.lerp(gradEnd, Colors.black, 0.35)!;

    return Padding(
      // Margin on every side -- including the bottom safe-area inset, so
      // the card floats clear of a gesture-nav bar on a notched device
      // instead of sitting flush against the screen edge the way the old
      // edge-to-edge bar did.
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: ClipRRect(
          // Fully rounded on every corner now -- a floating card, not a
          // bar anchored to the screen's bottom edge.
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            // Blur cost scales roughly with sigma^2 -- this bar sits over the
            // animated gradient sweep above, which repaints continuously for
            // as long as the app is open, so every point of sigma here is a
            // permanent, ongoing GPU cost on every screen, not a one-off.
            // 18 still reads as frosted glass at typical bar heights.
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Stack(
              // Only the Row of nav items below is a non-positioned child --
              // it alone determines the Stack's height. The tint and sheen
              // are `Positioned.fill`, sized to match rather than sizing the
              // Stack: a plain (non-positioned) Container with a decoration
              // but no child or size happily expands to fill the entire
              // bounded height it's offered, which is exactly what happened
              // here previously -- the bar grew to cover the whole screen
              // instead of sitting at its intended ~64dp.
              children: [
                // The tint: semi-transparent so the blur behind it (the page
                // content scrolling underneath) is genuinely visible through
                // it -- that's what actually makes it read as glass rather
                // than a flat coloured bar. Only this animated layer sits
                // inside `AnimatedBuilder` -- it used to wrap the entire bar
                // (including the BackdropFilter and all InkWells below),
                // which rebuilt that whole static subtree 60x/second for as
                // long as the app was open, for the sake of a gradient sweep
                // only this one box needs.
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_drift, _react]),
                    builder: (context, _) {
                      final t = _drift.value;
                      // The reactive term eases from the previously-selected
                      // tab's position to the newly-selected one -- added to
                      // the ambient sweep's own alignment rather than
                      // replacing it, so the drift never visibly stops.
                      final reactT = Curves.easeOutCubic.transform(_react.value);
                      final reactDx = (_reactFromT + (_reactToT - _reactFromT) * reactT) * 0.35;
                      // A wide horizontal sweep -- large enough to actually
                      // read as motion, unlike a tiny alignment nudge.
                      final begin = Alignment.lerp(const Alignment(-1.6, -1), const Alignment(1.0, -1), t)!;
                      final end = Alignment.lerp(const Alignment(1.6, 1), const Alignment(-1.0, 1), t)!;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(begin.x + reactDx, begin.y),
                            end: Alignment(end.x + reactDx, end.y),
                            colors: [
                              gradStart.withValues(alpha: 0.68),
                              gradEnd.withValues(alpha: 0.68),
                              gradDeep.withValues(alpha: 0.68),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // iOS-style sheen: a soft highlight along the top edge, fading
                // out fast -- the detail that reads as "glass" over "coloured
                // plastic." Static, so built once rather than per tick.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.35],
                          colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.0)],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var i = 0; i < GlassNavBar._items.length; i++)
                        _NavItem(
                          item: GlassNavBar._items[i],
                          selected: i == widget.selectedIndex,
                          onTap: () => widget.onDestinationSelected(i),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final ({IconData filled, IconData outline, String label}) item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final onPrimary = context.palette.onPrimary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? onPrimary.withValues(alpha: 0.26) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  selected ? item.filled : item.outline,
                  size: 23,
                  color: onPrimary.withValues(alpha: selected ? 1.0 : 0.72),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  color: onPrimary.withValues(alpha: selected ? 1.0 : 0.72),
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

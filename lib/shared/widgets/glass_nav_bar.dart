/// The bottom tab bar — an iOS-style frosted-glass pill. The gradient
/// beneath the blur is deliberately semi-transparent, not opaque: an opaque
/// fill defeats the point of `BackdropFilter` entirely, since there'd be
/// nothing visible left to blur. The tint sweeps a wide, clearly visible arc
/// on a continuous loop -- an animated-gradient stand-in for a literal video
/// background (no video asset exists, and one would cost real APK size and
/// battery for a bottom bar).
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
    (filled: Icons.person_rounded, outline: Icons.person_outline_rounded, label: 'Me'),
  ];

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar> with SingleTickerProviderStateMixin {
  static const _normalPeriod = Duration(seconds: 7);
  static const _hoverPeriod = Duration(milliseconds: 900);

  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: _normalPeriod);
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

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              // (including the BackdropFilter and all 5 InkWells below),
              // which rebuilt that whole static subtree 60x/second for as
              // long as the app was open, for the sake of a gradient sweep
              // only this one box needs.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _drift,
                  builder: (context, _) {
                    final t = _drift.value;
                    // A wide horizontal sweep -- large enough to actually
                    // read as motion, unlike a tiny alignment nudge.
                    final begin = Alignment.lerp(const Alignment(-1.6, -1), const Alignment(1.0, -1), t)!;
                    final end = Alignment.lerp(const Alignment(1.6, 1), const Alignment(-1.0, 1), t)!;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: begin,
                          end: end,
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
                padding: EdgeInsets.only(top: 10, bottom: 10 + bottomInset),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.45), width: 1)),
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
                  color: selected ? Colors.white.withValues(alpha: 0.26) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  selected ? item.filled : item.outline,
                  size: 23,
                  color: Colors.white.withValues(alpha: selected ? 1.0 : 0.72),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: selected ? 1.0 : 0.72),
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

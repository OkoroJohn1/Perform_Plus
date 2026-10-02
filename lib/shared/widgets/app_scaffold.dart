/// The five-tab shell.
///
/// Your original board had 14 sibling destinations hanging off the
/// dashboard with a 5-item bottom bar — Roadmap, Reading, Exams, Reports,
/// Achievements, Settings and Notifications had no home. Grouping by what
/// the student is DOING rather than by feature fixes that, and tells you
/// where a future feature belongs without re-litigating it every sprint.
///
///   Academics -> "where do I stand"
///   Study     -> "what do I do about it"
///
/// Notifications live as a bell in each tab's header, not a tab — pushed as
/// `Routes.notifications`, nested under this same shell so the bottom nav
/// stays visible and (see [_AppScaffoldState._lastTabIndex]) still shows
/// whichever tab the student came from, not a reset to Home.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../providers/advisor_fab_position_provider.dart';
import 'advisor_fab.dart';
import 'glass_nav_bar.dart';

class AppScaffold extends ConsumerStatefulWidget {
  final Widget child;

  /// Manual override, defaulting true — the FAB is still automatically
  /// suppressed on the AI tab (redundant; you're already there) and Me
  /// (nothing to advise on) regardless of this flag, since a single
  /// `AppScaffold` wraps every tab and only it knows the current route.
  final bool showAdvisorFab;

  const AppScaffold({super.key, required this.child, this.showAdvisorFab = true});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  bool _fabExpanded = true;

  /// The last route that genuinely matched a tab. `/notifications` itself
  /// matches none (`Routes.tabIndexFor` returns -1 for it) — without this,
  /// the bottom nav would fall back to Home instead of staying on whatever
  /// tab the student pushed notifications from.
  int _lastTabIndex = 0;

  bool _handleScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      final expanded = notification.direction != ScrollDirection.reverse;
      if (expanded != _fabExpanded) setState(() => _fabExpanded = expanded);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final matched = Routes.tabIndexFor(location);
    if (matched >= 0) _lastTabIndex = matched;
    final index = matched >= 0 ? matched : _lastTabIndex;
    final currentTab = Routes.tabOrder[index];
    final onNotifications = location.startsWith(Routes.notifications);
    final autoShow = currentTab != Routes.ai && currentTab != Routes.me && !onNotifications;

    final scaffold = Scaffold(
      // Every tab now paints its own full-bleed light `#F7F7FB` surface --
      // this used to be `GradientScaffold`'s permanent dark gradient, back
      // when no tab had a light background of its own. That gradient is
      // gone now; left in place, it showed through as a dark smear behind
      // GlassNavBar's rounded top corners, the one place nothing else
      // covers this outer Scaffold's own background.
      backgroundColor: context.palette.background,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: widget.child,
      ),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(Routes.tabOrder[i]),
      ),
    );

    if (!widget.showAdvisorFab || !autoShow) return scaffold;

    // Freely draggable, not Scaffold's fixed `floatingActionButton` slot --
    // LayoutBuilder wraps the whole Stack (not the other way around):
    // `Positioned` must be a DIRECT child of `Stack` to receive its
    // StackParentData; nesting it inside LayoutBuilder's builder instead
    // (LayoutBuilder is itself a RenderObjectWidget) put a RenderObject
    // between them and threw "Incorrect use of ParentDataWidget".
    //
    // `scaffold` above is built ONCE per genuine `AppScaffold` rebuild
    // (route change, scroll-direction flip) and handed down as a plain
    // child -- `_DraggableFab` owns its OWN drag state below it in the
    // tree, so dragging never re-runs this whole tab's widget subtree.
    // It used to: `_liveDragFraction`/`_snapping` lived on this State,
    // so every single pixel of drag called `setState` here, rebuilding
    // `scaffold` (the ENTIRE visible tab -- every card, chart, list) from
    // scratch on every pointer-move event. On a slower device that
    // out-paced what a full-tab rebuild could keep up with each frame,
    // which is exactly what made the FAB feel like it was "barely"
    // following the finger instead of tracking it directly.
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          scaffold,
          _DraggableFab(expanded: _fabExpanded, constraints: constraints),
        ],
      ),
    );
  }
}

class _DraggableFab extends ConsumerStatefulWidget {
  final bool expanded;
  final BoxConstraints constraints;

  const _DraggableFab({required this.expanded, required this.constraints});

  @override
  ConsumerState<_DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends ConsumerState<_DraggableFab> {
  /// Live during an active drag, overriding the persisted fraction until
  /// the gesture ends -- avoids writing to Drift on every pixel of
  /// movement, only once when the student lets go.
  Offset? _liveDragFraction;

  /// True only for the post-release "magnet" animation to the nearest
  /// screen edge -- zero duration otherwise, so the FAB tracks the finger
  /// with no lag while actually being dragged.
  bool _snapping = false;

  static const _defaultFabFraction = Offset(0.86, 0.78);

  @override
  Widget build(BuildContext context) {
    final constraints = widget.constraints;
    final size = widget.expanded ? 56.0 : 40.0;
    final maxLeft = constraints.maxWidth - size;
    final maxTop = constraints.maxHeight - size;
    final fraction = _liveDragFraction ?? ref.watch(advisorFabPositionProvider) ?? _defaultFabFraction;
    final left = (fraction.dx * constraints.maxWidth).clamp(0.0, maxLeft <= 0 ? 0.0 : maxLeft);
    final top = (fraction.dy * constraints.maxHeight).clamp(0.0, maxTop <= 0 ? 0.0 : maxTop);

    return AnimatedPositioned(
      duration: _snapping ? const Duration(milliseconds: 260) : Duration.zero,
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      child: AdvisorFab(
        expanded: widget.expanded,
        onDragUpdate: (details) {
          if (maxLeft <= 0 || maxTop <= 0) return;
          // 1:1 with the raw pointer delta -- no smoothing, no lerp --
          // so the FAB sits exactly under the finger on every frame this
          // widget (and only this widget) rebuilds for.
          final newLeft = (left + details.delta.dx).clamp(0.0, maxLeft);
          final newTop = (top + details.delta.dy).clamp(0.0, maxTop);
          setState(() {
            _snapping = false;
            _liveDragFraction = Offset(newLeft / constraints.maxWidth, newTop / constraints.maxHeight);
          });
        },
        // Magnet: snap to whichever screen edge -- left or right -- the
        // FAB's centre is closest to when released, keeping the vertical
        // drop position as-is.
        onDragEnd: (_) {
          if (constraints.maxWidth <= 0) return;
          final centerLeft = left + (widget.expanded ? 28.0 : 20.0);
          final targetLeft = centerLeft < constraints.maxWidth / 2 ? 0.0 : maxLeft;
          final settled = Offset(
            maxLeft <= 0 ? 0.0 : targetLeft / constraints.maxWidth,
            top / constraints.maxHeight,
          );
          setState(() {
            _snapping = true;
            _liveDragFraction = settled;
          });
          ref.read(advisorFabPositionProvider.notifier).setFraction(settled);
        },
      ),
    );
  }
}

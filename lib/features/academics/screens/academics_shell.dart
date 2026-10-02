/// Academics tab — "where do I stand" (see AGENTS.md's tab-grouping
/// rationale). Three views it actually owns: Results, Roadmap, Reports.
///
/// The mockup's "My Results"/"All Semesters" segments were the same
/// dataset under two names; this replaces them with the three real views.
/// Reports is locked until at least one semester exists — a report over no
/// data isn't a report, it's an empty page pretending to be one.
///
/// Shares the dashboard's tinted `#F7F7FB` surface (`DashboardPalette`) so
/// the two tabs feel like one app; Results, Roadmap and Reports are all
/// rebuilt onto it now.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/repositories/notification_provider.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../home/screens/notifications_panel.dart';
import 'reports_view.dart';
import 'results_view.dart';
import 'roadmap_view.dart';

enum AcademicsTab { results, roadmap, reports }

class AcademicsShell extends ConsumerStatefulWidget {
  const AcademicsShell({super.key});

  @override
  ConsumerState<AcademicsShell> createState() => _AcademicsShellState();
}

class _AcademicsShellState extends ConsumerState<AcademicsShell> {
  AcademicsTab _tab = AcademicsTab.results;

  void _selectTab(AcademicsTab tab, {required bool reportsLocked}) {
    if (tab == AcademicsTab.reports && reportsLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a semester to unlock reports.')),
      );
      return;
    }
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final standing = ref.watch(standingProvider);
    final reportsLocked = !standing.hasData;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: context.palette.background,
        drawer: const AppDrawer(),
        appBar: const _AcademicsAppBar(),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 16),
              _AcademicsSegmentedControl(
                tab: _tab,
                reportsLocked: reportsLocked,
                onChanged: (t) => _selectTab(t, reportsLocked: reportsLocked),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: switch (_tab) {
                  AcademicsTab.results => const ResultsView(),
                  AcademicsTab.roadmap => const RoadmapView(),
                  AcademicsTab.reports => const ReportsView(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcademicsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AcademicsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DashboardPalette.scaffoldBackground,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Builder(
                  builder: (context) => Material(
                    color: context.palette.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.menu, size: 22, color: context.palette.primary),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Academics',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.palette.bodyText,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const _NotificationBell(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider.select((n) => n.any((x) => !x.isRead)));

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          Center(
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 24, color: Color(0xFF4B5563)),
              onPressed: () => showNotificationsPanel(context),
            ),
          ),
          if (unread)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: context.palette.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AcademicsSegmentedControl extends StatelessWidget {
  final AcademicsTab tab;
  final bool reportsLocked;
  final ValueChanged<AcademicsTab> onChanged;

  const _AcademicsSegmentedControl({
    required this.tab,
    required this.reportsLocked,
    required this.onChanged,
  });

  static const _labels = {
    AcademicsTab.results: 'RESULTS',
    AcademicsTab.roadmap: 'ROADMAP',
    AcademicsTab.reports: 'REPORTS',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = constraints.maxWidth / AcademicsTab.values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: slotWidth * tab.index,
                width: slotWidth,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.palette.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final t in AcademicsTab.values)
                    Expanded(
                      child: _Segment(
                        label: _labels[t]!,
                        selected: t == tab,
                        locked: t == AcademicsTab.reports && reportsLocked,
                        onTap: () => onChanged(t),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : context.palette.secondaryText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: double.infinity,
        child: Opacity(
          opacity: locked ? 0.5 : 1.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 15.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (locked) ...[
                const SizedBox(width: 4),
                Icon(Icons.lock_outline, size: 14, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

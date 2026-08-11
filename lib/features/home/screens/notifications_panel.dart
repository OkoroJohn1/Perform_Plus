/// Notifications panel, opened from the Home header bell.
///
/// Every item is derived live from real state — calculation issues, whether
/// a goal is set, the current feasibility reading. No fabricated activity
/// log and no invented timestamps, since there is no event history to draw
/// them from honestly.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/repositories/goal_provider.dart';
import '../../../domain/engine/projection_solver.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/notifications_provider.dart';

enum _Category { academic, ai, system }

class _NotificationItem {
  final _Category category;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _NotificationItem({
    required this.category,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
}

Future<void> showNotificationsPanel(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const NotificationsPanel(),
  );
}

class NotificationsPanel extends ConsumerStatefulWidget {
  const NotificationsPanel({super.key});

  @override
  ConsumerState<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends ConsumerState<NotificationsPanel> {
  _Category? _filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final standing = ref.watch(standingProvider);
    final goal = ref.watch(goalProvider);
    final projection = ref.watch(targetProjectionProvider);

    final items = <_NotificationItem>[
      for (final issue in standing.issues)
        _NotificationItem(
          category: _Category.academic,
          icon: Icons.error_outline,
          title: '${issue.courseCode} wasn\'t counted',
          subtitle: issue.message,
          onTap: () {
            Navigator.of(context).pop();
            context.go(Routes.academics);
          },
        ),
      if (goal == null)
        _NotificationItem(
          category: _Category.system,
          icon: Icons.flag_outlined,
          title: 'No goal set yet',
          subtitle: 'Set a target classification to track your progress toward it.',
          onTap: () {
            Navigator.of(context).pop();
            context.go(Routes.goalSetting);
          },
        ),
      if (projection != null)
        _NotificationItem(
          category: _Category.ai,
          icon: Icons.auto_awesome_outlined,
          title: 'Goal status: ${projection.feasibility.label}',
          subtitle: projection.targetLabel == null
              ? 'Based on your current standing.'
              : '${projection.targetLabel} — based on your current standing.',
        ),
    ];

    final visible =
        _filter == null ? items : items.where((i) => i.category == _filter).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notifications', style: theme.textTheme.titleLarge),
                TextButton(
                  onPressed: () =>
                      ref.read(notificationsReadProvider.notifier).state = true,
                  child: const Text('Mark all as read'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Academic',
                    selected: _filter == _Category.academic,
                    onTap: () => setState(() => _filter = _Category.academic),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'AI',
                    selected: _filter == _Category.ai,
                    onTap: () => setState(() => _filter = _Category.ai),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'System',
                    selected: _filter == _Category.system,
                    onTap: () => setState(() => _filter = _Category.system),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: visible.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none,
                      title: 'Nothing to see here',
                      message: 'You\'re all caught up.',
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final item = visible[i];
                        return ListTile(
                          leading: Icon(item.icon, color: theme.colorScheme.primary),
                          title: Text(item.title),
                          subtitle: Text(item.subtitle),
                          onTap: item.onTap,
                        );
                      },
                    ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      );
}

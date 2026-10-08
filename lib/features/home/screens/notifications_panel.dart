/// The notifications screen — pushed from the header bell on Home,
/// Academics, Advisor and Study (not Me, which has nothing to notify
/// about), never a bottom-nav destination. Nested under the same shell as
/// the tabs (see `app_router.dart`/`AppScaffold`) so the bottom bar stays
/// visible with whatever tab the student came from still active.
///
/// Every notification is generated locally from a real app event (see
/// `domain/models/app_notification.dart`'s content-generation functions,
/// wired up in `data/repositories/notification_provider.dart`) and stored
/// in Drift — never a fabricated activity log.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/notification_provider.dart';
import '../../../domain/models/app_notification.dart';
import '../../../shared/widgets/glass_top_bar.dart';
import '../../../shared/widgets/quick_settings_sheets.dart';
import '../services/notification_permission_service.dart';
import '../widgets/notification_bell_illustration.dart';

/// Kept as a function (not a route literal) at call sites so the four tab
/// headers didn't need touching when this moved from a bottom sheet to a
/// pushed route.
void showNotificationsPanel(BuildContext context) => context.push(Routes.notifications);

enum _Tab { all, unread }

enum _RecencyGroup { today, yesterday, thisWeek, earlier }

_RecencyGroup _groupFor(DateTime createdAt, DateTime now) {
  final created = DateTime(createdAt.year, createdAt.month, createdAt.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(created).inDays;
  if (diff <= 0) return _RecencyGroup.today;
  if (diff == 1) return _RecencyGroup.yesterday;
  if (diff <= 7) return _RecencyGroup.thisWeek;
  return _RecencyGroup.earlier;
}

String _groupTitle(_RecencyGroup g) => switch (g) {
      _RecencyGroup.today => 'Today',
      _RecencyGroup.yesterday => 'Yesterday',
      _RecencyGroup.thisWeek => 'This week',
      _RecencyGroup.earlier => 'Earlier',
    };

String _timestampFor(DateTime createdAt, DateTime now) => switch (_groupFor(createdAt, now)) {
      _RecencyGroup.today => DateFormat.jm().format(createdAt),
      _RecencyGroup.yesterday => 'Yesterday',
      _RecencyGroup.thisWeek => DateFormat.E().format(createdAt),
      _RecencyGroup.earlier => DateFormat('d MMM').format(createdAt),
    };

extension _NotificationPresentation on AppNotification {
  bool get _cgpaRising => payload['rising'] == 'true';

  IconData get icon => switch (type) {
        AppNotificationType.resultAdded => Icons.school_outlined,
        AppNotificationType.cgpaChanged => _cgpaRising ? Icons.trending_up : Icons.trending_down,
        AppNotificationType.goalPaceChanged => Icons.flag_outlined,
        AppNotificationType.achievementUnlocked => Icons.emoji_events_outlined,
        AppNotificationType.studyReminder => Icons.schedule,
        AppNotificationType.streakAtRisk => Icons.local_fire_department,
        AppNotificationType.carryoverFlagged => Icons.replay,
        AppNotificationType.cgpaStandingReminder => Icons.insights_outlined,
      };

  Color colorFor(AppPalette palette) => switch (type) {
        AppNotificationType.resultAdded => palette.primary,
        AppNotificationType.cgpaChanged => _cgpaRising ? palette.success : palette.amber,
        AppNotificationType.goalPaceChanged => palette.primary,
        AppNotificationType.achievementUnlocked => palette.success,
        AppNotificationType.studyReminder => const Color(0xFFEA580C),
        AppNotificationType.streakAtRisk => const Color(0xFFEA580C),
        AppNotificationType.carryoverFlagged => palette.amber,
        AppNotificationType.cgpaStandingReminder => palette.primary,
      };

  /// Where tapping the row routes to — a result notification opens
  /// Academics (where that semester lives), an achievement opens Me.
  String get destinationRoute => switch (type) {
        AppNotificationType.resultAdded ||
        AppNotificationType.cgpaChanged ||
        AppNotificationType.carryoverFlagged ||
        AppNotificationType.cgpaStandingReminder =>
          Routes.academics,
        AppNotificationType.goalPaceChanged => Routes.home,
        AppNotificationType.achievementUnlocked => Routes.me,
        AppNotificationType.studyReminder || AppNotificationType.streakAtRisk => Routes.study,
      };
}

class NotificationsPanel extends ConsumerStatefulWidget {
  final NotificationPermissionChecker? debugPermissionChecker;

  const NotificationsPanel({super.key, this.debugPermissionChecker});

  @override
  ConsumerState<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends ConsumerState<NotificationsPanel> {
  late final NotificationPermissionChecker _permission =
      widget.debugPermissionChecker ?? const SystemNotificationPermissionChecker();

  _Tab _tab = _Tab.all;
  bool? _permissionGranted;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await _permission.isGranted();
    if (mounted) setState(() => _permissionGranted = granted);
  }

  Future<void> _requestPermission() async {
    final granted = await _permission.request();
    if (mounted) setState(() => _permissionGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final visible = _tab == _Tab.all ? notifications : notifications.where((n) => !n.isRead).toList();
    final now = DateTime.now();

    final grouped = <_RecencyGroup, List<AppNotification>>{};
    for (final n in visible) {
      grouped.putIfAbsent(_groupFor(n.createdAt, now), () => []).add(n);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: context.palette.background,
        appBar: _NotificationsAppBar(onSettingsTap: () => showNotificationSettingsSheet(context)),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            children: [
              Center(
                child: NotificationBellIllustration(
                  unreadCount: unreadCount,
                  accent: context.palette.primary,
                  accentGradientStart: context.palette.primaryGradientStart,
                  accentDark: context.palette.primaryGradientEnd,
                ),
              ),
              const SizedBox(height: 8),
              _SegmentedTabs(
                tab: _tab,
                unreadCount: unreadCount,
                onChanged: (t) => setState(() => _tab = t),
              ),
              // Permission-aware, not data-aware: a day-one user with zero
              // notifications still wants the nudge to enable them so
              // future ones actually arrive.
              if (_permissionGranted == false) ...[
                const SizedBox(height: 20),
                _PermissionHeroBanner(onTurnOn: _requestPermission),
              ],
              if (notifications.isEmpty)
                const _EmptyAll()
              else if (visible.isEmpty)
                const _EmptyUnread()
              else
                for (final group in _RecencyGroup.values)
                  if (grouped[group] != null) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _groupTitle(group),
                        style: TextStyle(
                          color: context.palette.bodyText,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(items: grouped[group]!, now: now),
                  ],
              const SizedBox(height: 20),
              _MarkAllReadButton(enabled: unreadCount > 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSettingsTap;

  const _NotificationsAppBar({required this.onSettingsTap});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return TopBarGlassBackground(
      // `SafeArea` here, not just a fixed `height: 64` -- this is a raw
      // custom `PreferredSizeWidget`, not the real Material `AppBar` (which
      // does this same push-down internally), so without it the back arrow
      // and settings icon render under the status bar overlay instead of
      // below it.
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, size: 24, color: context.palette.primary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Notifications',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.palette.bodyText,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: Icon(Icons.settings_outlined, size: 22, color: context.palette.secondaryText),
                    onPressed: onSettingsTap,
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

class _SegmentedTabs extends StatelessWidget {
  final _Tab tab;
  final int unreadCount;
  final ValueChanged<_Tab> onChanged;

  const _SegmentedTabs({required this.tab, required this.unreadCount, required this.onChanged});

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
          final slotWidth = constraints.maxWidth / 2;
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
                  Expanded(
                    child: _TabLabel(
                      label: 'ALL',
                      selected: tab == _Tab.all,
                      onTap: () => onChanged(_Tab.all),
                    ),
                  ),
                  Expanded(
                    child: _TabLabel(
                      label: 'UNREAD',
                      selected: tab == _Tab.unread,
                      count: unreadCount,
                      onTap: () => onChanged(_Tab.unread),
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

class _TabLabel extends StatelessWidget {
  final String label;
  final bool selected;
  final int? count;
  final VoidCallback onTap;

  const _TabLabel({required this.label, required this.selected, this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : context.palette.secondaryText;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontSize: 15.5, fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFFDC2626), borderRadius: BorderRadius.all(Radius.circular(999))),
                child: Text(
                  '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionHeroBanner extends StatelessWidget {
  final VoidCallback onTurnOn;

  const _PermissionHeroBanner({required this.onTurnOn});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('notificationsPermissionBanner'),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [context.palette.primary.withValues(alpha: 0.22), context.palette.surface]
              : const [Color(0xFFF1EFFE), Color(0xFFFAF9FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay updated',
                  style: TextStyle(color: context.palette.bodyText, fontSize: 23, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  "Turn on notifications so you don't miss result reminders.",
                  style: TextStyle(color: context.palette.secondaryText, fontSize: 15.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    key: const ValueKey('turnOnNotificationsTap'),
                    onPressed: onTurnOn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_active_outlined, size: 18, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Turn on', style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Icon(Icons.notifications_none_rounded, size: 56, color: context.palette.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends ConsumerWidget {
  final List<AppNotification> items;
  final DateTime now;

  const _SectionCard({required this.items, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 74, color: Color(0xFFECECF1)),
            _NotificationRow(notification: items[i], now: now),
          ],
        ],
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  final AppNotification notification;
  final DateTime now;

  const _NotificationRow({required this.notification, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = notification.colorFor(context.palette);
    final unread = !notification.isRead;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: const Color(0xFFDC2626),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        final removed = await ref.read(notificationsProvider.notifier).dismiss(notification.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification dismissed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => ref.read(notificationsProvider.notifier).restore(removed),
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          ref.read(notificationsProvider.notifier).markRead(notification.id);
          context.go(notification.destinationRoute);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            border: unread ? Border(left: BorderSide(color: context.palette.primary, width: 3)) : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(notification.icon, size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.palette.bodyText, fontSize: 16.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.palette.secondaryText, fontSize: 14.5),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 76,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _timestampFor(notification.createdAt, now),
                      style: TextStyle(color: context.palette.secondaryText, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: unread ? 8 : 6,
                      height: unread ? 8 : 6,
                      decoration: BoxDecoration(
                        color: unread ? context.palette.primary : const Color(0xFFD1D5DB),
                        shape: BoxShape.circle,
                      ),
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

class _MarkAllReadButton extends ConsumerStatefulWidget {
  final bool enabled;

  const _MarkAllReadButton({required this.enabled});

  @override
  ConsumerState<_MarkAllReadButton> createState() => _MarkAllReadButtonState();
}

class _MarkAllReadButtonState extends ConsumerState<_MarkAllReadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          key: const ValueKey('markAllReadButtonTap'),
          onTap: enabled ? () => ref.read(notificationsProvider.notifier).markAllRead() : null,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.palette.primary.withValues(alpha: _pressed ? 0.12 : 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_read_outlined, size: 20, color: context.palette.primary),
                const SizedBox(width: 10),
                Text(
                  'Mark all as read',
                  style: TextStyle(color: context.palette.primary, fontSize: 16.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyAll extends StatelessWidget {
  const _EmptyAll();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // No second bell illustration here -- the big one above the
          // segmented tabs is already always on screen, including this
          // empty state; a near-identical one directly below it would just
          // be the same picture twice.
          Icon(Icons.inbox_outlined, size: 48, color: context.palette.emptyIcon),
          const SizedBox(height: 20),
          Text(
            'Nothing yet',
            style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              "We'll tell you when your CGPA changes or a streak is at risk.",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.secondaryText, fontSize: 15.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyUnread extends StatelessWidget {
  const _EmptyUnread();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: 0.5,
            child: Icon(Icons.check_circle_outline, size: 44, color: context.palette.success),
          ),
          SizedBox(height: 16),
          Text(
            "You're all caught up",
            style: TextStyle(color: context.palette.bodyText, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

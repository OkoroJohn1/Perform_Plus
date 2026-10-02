import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/repositories/notification_provider.dart';
import 'package:perform_plus/domain/models/app_notification.dart';
import 'package:perform_plus/features/home/screens/notifications_panel.dart';
import 'package:perform_plus/features/home/services/notification_permission_service.dart';

class _FakePermissionChecker implements NotificationPermissionChecker {
  bool granted;

  _FakePermissionChecker({required this.granted});

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<bool> request() async {
    granted = true;
    return granted;
  }
}

/// The hero bell and the empty-state bell both rock on a perpetual
/// `AnimationController.repeat()` (suppressed under reduced motion) --
/// `pumpAndSettle` never settles against a perpetual animation, so every
/// test here disables animations the same way the widget already knows to
/// respect.
Widget _noAnimations(Widget child) =>
    MediaQuery(data: const MediaQueryData(disableAnimations: true), child: child);

AppNotification _unread(String id, DateTime createdAt) => AppNotification(
      id: id,
      type: AppNotificationType.resultAdded,
      title: 'Semester result added',
      body: 'Your results are saved.',
      createdAt: createdAt,
    );

void main() {
  group('permission-aware hero banner', () {
    testWidgets('is shown when the system notification permission is NOT granted',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith((ref) => NotificationsController.seeded(const [])),
          ],
          child: _noAnimations(
            MaterialApp(
              home:
                  NotificationsPanel(debugPermissionChecker: _FakePermissionChecker(granted: false)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('notificationsPermissionBanner')), findsOneWidget);
      expect(find.text('Stay updated'), findsOneWidget);
    });

    testWidgets('is hidden when the system notification permission is already granted',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith((ref) => NotificationsController.seeded(const [])),
          ],
          child: _noAnimations(
            MaterialApp(
              home:
                  NotificationsPanel(debugPermissionChecker: _FakePermissionChecker(granted: true)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('notificationsPermissionBanner')), findsNothing);
      expect(find.text('Stay updated'), findsNothing);
    });
  });

  testWidgets('marking all as read in the panel clears the unread badge app-wide',
      (tester) async {
    final now = DateTime(2026, 8, 24, 10);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) => NotificationsController.seeded([_unread('n1', now), _unread('n2', now)]),
          ),
        ],
        child: _noAnimations(
          MaterialApp(
            home: Column(
              children: [
                // Stands in for the real header bell on Home/Academics/AI/Study,
                // which reads the exact same provider -- proving the update
                // propagates app-wide, not just inside the panel that wrote it.
                Consumer(
                  builder: (context, ref, _) {
                    final hasUnread =
                        ref.watch(notificationsProvider.select((n) => n.any((x) => !x.isRead)));
                    return Text(hasUnread ? 'bell: unread' : 'bell: caught up');
                  },
                ),
                Expanded(
                  child: NotificationsPanel(
                    debugPermissionChecker: _FakePermissionChecker(granted: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('bell: unread'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('markAllReadButtonTap')));
    await tester.pumpAndSettle();

    expect(find.text('bell: caught up'), findsOneWidget);
  });
}

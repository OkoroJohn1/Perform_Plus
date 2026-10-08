/// The one-time "turn on notifications?" nudge -- a frosted glass card
/// over a blurred Dashboard, iOS-permission-dialog style (title, message,
/// a divider, then two buttons split by a vertical divider). Tapping
/// "Allow" fires the REAL system permission request directly
/// (`Permission.notification.request()`) -- never a redirect to the
/// Settings app, which is what "Open system settings" elsewhere in this
/// app (the Notifications panel's own permission banner) is for when the
/// student has already permanently denied it.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../home/services/notification_permission_service.dart';
import '../providers/notification_prompt_provider.dart';

Future<void> showNotificationPromptDialog(
  BuildContext context,
  WidgetRef ref, {
  NotificationPermissionChecker? debugPermissionChecker,
}) async {
  final accepted = await showGeneralDialog<bool>(
    context: context,
    barrierLabel: 'Turn on notifications?',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, _, __) => const _NotificationPromptOverlay(),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
      );
    },
  );

  await ref.read(notificationPromptProvider.notifier).dismiss();
  if (accepted == true) {
    final checker = debugPermissionChecker ?? const SystemNotificationPermissionChecker();
    await checker.request();
  }
}

class _NotificationPromptOverlay extends StatelessWidget {
  const _NotificationPromptOverlay();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(false),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.30)),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.surface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.1),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 36, offset: const Offset(0, 14)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [palette.primaryGradientStart, palette.primaryGradientEnd],
                                ),
                              ),
                              child: Icon(Icons.notifications_active_outlined, color: palette.onPrimary, size: 26),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Turn on notifications?',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: palette.bodyText, fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Get a daily nudge to read and a reminder of where your CGPA stands -- '
                              'up to a few times a day, never more.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: palette.secondaryText, fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: palette.divider),
                      SizedBox(
                        height: 50,
                        child: Row(
                          children: [
                            Expanded(
                              child: _PromptButton(
                                key: const ValueKey('notificationPromptDenyTap'),
                                label: "Don't Allow",
                                color: palette.secondaryText,
                                bold: false,
                                onTap: () => Navigator.of(context).pop(false),
                              ),
                            ),
                            SizedBox(height: double.infinity, child: VerticalDivider(width: 1, color: palette.divider)),
                            Expanded(
                              child: _PromptButton(
                                key: const ValueKey('notificationPromptAllowTap'),
                                label: 'Allow',
                                color: palette.primary,
                                bold: true,
                                onTap: () => Navigator.of(context).pop(true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromptButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool bold;
  final VoidCallback onTap;

  const _PromptButton({super.key, required this.label, required this.color, required this.bold, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 16, fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

/// Me tab. Achievements show a LOCKED row with visible criteria —
/// locked-but-visible motivates, hidden does not. Built as one scrollable
/// screen (Profile + Achievements + Settings + Logout) rather than separate
/// routes, since `routes.dart` has a single `/me` path.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/seed/nigerian_institutions.dart';
import '../../../shared/widgets/locked_feature_row.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/profile_provider.dart';
import '../../auth/widgets/profile_form.dart';
import '../providers/settings_provider.dart';

class MeShell extends ConsumerWidget {
  const MeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(studentProfileProvider);
    final record = ref.watch(academicRecordProvider);
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Me')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      profile?.initials ?? '?',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(profile?.fullName ?? 'Add your profile',
                      style: theme.textTheme.titleMedium),
                  if (profile != null) ...[
                    Text('${profile.regNumber} · ${profile.department}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      'Academic Timeline: ${profile.entryYear} → ${profile.expectedGraduationYear}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _editProfile(context, ref),
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const LockedFeatureRow(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            subtitle: 'Streaks and milestones you\'ve earned',
          ),
          const SizedBox(height: 16),
          Text('Settings', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark Mode'),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (v) => ref.read(themeModeProvider.notifier).state =
                      v ? ThemeMode.dark : ThemeMode.light,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  value: notificationsEnabled,
                  onChanged: (v) =>
                      ref.read(notificationsEnabledProvider.notifier).state = v,
                ),
                ListTile(
                  leading: const Icon(Icons.grading_outlined),
                  title: const Text('Grading Scheme'),
                  subtitle: Text(record.scheme.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(Routes.institutionSetup),
                ),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('AI Preferences'),
                  subtitle: const Text('Nothing to configure yet'),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy & Security'),
                  subtitle: const Text('Your data stays on this device until you sign in'),
                ),
                const LockedFeatureRow(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Subscription',
                  subtitle: 'Premium AI credits and unlimited reports',
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: theme.colorScheme.error),
                  title: Text('Log out', style: TextStyle(color: theme.colorScheme.error)),
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editProfile(BuildContext context, WidgetRef ref) {
    final profile = ref.read(studentProfileProvider);
    final institutionId = ref.read(academicRecordProvider).scheme.institutionId;
    final institution =
        nigerianInstitutions.where((i) => i.id == institutionId).firstOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: ProfileForm(
            initial: profile,
            institution: institution,
            saveLabel: 'Save',
            onSave: (updated) {
              ref.read(studentProfileProvider.notifier).state = updated;
              Navigator.of(sheetContext).pop();
            },
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authStateProvider.notifier).signOut();
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

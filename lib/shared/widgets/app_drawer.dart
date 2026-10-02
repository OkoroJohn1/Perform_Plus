/// The hamburger-menu drawer shared by every tab shell (Dashboard,
/// Academics, Advisor, Study — Me has its own settings inline instead, see
/// `me_shell.dart`, but stays reachable from here too). One implementation
/// rather than a near-identical private copy per screen, so adding
/// something here (Theme colour/Appearance quick-access, below) reaches
/// every tab at once instead of needing five separate edits.
///
/// Theme colour and Appearance are also full rows inside the Me tab's App
/// section — deliberately duplicated for reachability, not moved: a
/// student switching between Home and Academics shouldn't have to detour
/// through Me just to flip Light/Dark.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_accent_provider.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../domain/models/student_profile.dart';
import 'quick_settings_sheets.dart';

class AppDrawer extends ConsumerWidget {
  final StudentProfile? profile;

  const AppDrawer({super.key, this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = profile?.fullName;
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(themeAccentProvider);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    void go(String route) {
      Navigator.of(context).pop();
      if (currentLocation != route) context.go(route);
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                name?.trim().isNotEmpty == true ? name! : 'Perform+',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            const _DrawerSectionLabel('Navigate'),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => go(Routes.home),
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Academics'),
              onTap: () => go(Routes.academics),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Advisor'),
              onTap: () => go(Routes.ai),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Study'),
              onTap: () => go(Routes.study),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Me'),
              onTap: () => go(Routes.me),
            ),
            const Divider(height: 1),
            const _DrawerSectionLabel('Quick settings'),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Appearance'),
              subtitle: Text(themeModeLabel(themeMode)),
              onTap: () => showAppearanceSheet(context, ref, themeMode),
            ),
            ListTile(
              key: const ValueKey('drawerThemeColorTap'),
              leading: const Icon(Icons.color_lens_outlined),
              title: const Text('Theme colour'),
              subtitle: Text(accent.label),
              onTap: () => showThemeColorSheet(context, ref, accent),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('More settings'),
              subtitle: const Text('Account, grading scheme, data & more'),
              onTap: () => go(Routes.me),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String label;

  const _DrawerSectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: OnboardingLightPalette.secondaryText,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );
}

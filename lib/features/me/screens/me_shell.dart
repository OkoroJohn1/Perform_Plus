/// Me tab -- identity, achievements, and every settings section, all in one
/// scrollable view. There is no separate "Settings" screen to push through
/// any more: everything that used to live behind a single "Settings" row
/// lives directly here now, one real implementation per concern rather than
/// a shallow duplicate here and a deep one behind a tap.
///
/// Achievements show a LOCKED row with visible criteria stated — locked-
/// but-visible motivates, hidden does not; a day-one user has earned
/// nothing and the shields render honestly grey, never pre-coloured (see
/// `BadgeShield`). Sign-out is a two-tier confirmation: the first dialog
/// offers an unchecked "also remove my data" box; only checking it AND
/// confirming a second, fully-named dialog actually deletes anything — a
/// plain sign-out always leaves local data untouched, since there is no
/// remote copy of a student's results to recover it from yet.
///
/// The Academic section is the one that actually matters: a wrong repeat
/// policy silently corrupts every CGPA computed under it (see
/// `grading_scheme.dart`'s doc comment), and this is the only place a
/// student can correct one the app guessed wrong. Rows use the current
/// theme accent (`Theme.of(context).colorScheme.primary`, set by the "Theme
/// colour" row below) rather than a hardcoded purple, so switching accent
/// actually shows up here -- except the Destructive section, where #DC2626
/// always means the same thing regardless of accent.
library;

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/performance_flag.dart';
import '../../../core/theme/theme_accent_provider.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/repositories/achievement_provider.dart';
import '../../../data/repositories/goal_provider.dart';
import '../../../shared/widgets/glass_top_bar.dart';
import '../../../data/repositories/note_provider.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/seed/nigerian_institutions.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/models/achievement.dart';
import '../../../domain/models/grading_scheme.dart';
import '../../../shared/widgets/badge_shield.dart';
import '../../../shared/widgets/quick_settings_sheets.dart';
import '../../auth/providers/pin_provider.dart';
import '../../auth/providers/security_questions_provider.dart';
import '../../auth/screens/pin_setup_sheet.dart';
import '../../auth/screens/security_questions_setup_sheet.dart';
import '../../auth/widgets/pin_pad.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/profile_provider.dart';
import '../services/data_export_service.dart';
import '../widgets/sign_out_dialogs.dart';

String _fmt(double v) => v.toStringAsFixed(2);

({Color color, IconData icon}) _badgeAppearance(BuildContext context, BadgeId id) => switch (id) {
      BadgeId.consistentLearner => (color: const Color(0xFFEA580C), icon: Icons.local_fire_department),
      BadgeId.topPerformer => (color: GpaRevealPalette.confettiAmber, icon: Icons.emoji_events),
      BadgeId.improvementKing => (color: context.palette.success, icon: Icons.trending_up),
      BadgeId.firstSteps => (color: context.palette.primary, icon: Icons.flag),
    };

class MeShell extends ConsumerStatefulWidget {
  const MeShell({super.key});

  @override
  ConsumerState<MeShell> createState() => _MeShellState();
}

class _MeShellState extends ConsumerState<MeShell> {
  /// Badges already unlocked the moment this screen was first built this
  /// session -- only a badge earned AFTER that pulses; one already unlocked
  /// on a prior visit renders solid, no replay.
  late final Set<BadgeId> _seenAtMount = ref.read(achievementsProvider).keys.toSet();

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(studentProfileProvider);
    final record = ref.watch(academicRecordProvider);
    final standing = ref.watch(standingProvider);
    final streak = ref.watch(notesProvider.select((s) => s.displayStreak));
    final achievements = ref.watch(achievementsProvider);
    final auth = ref.watch(authStateProvider).valueOrNull;
    final notesState = ref.watch(notesProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(themeAccentProvider);
    final pinState = ref.watch(pinProvider);

    final institution =
        nigerianInstitutions.firstWhereOrNull((i) => i.id == record.scheme.institutionId);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: context.palette.background,
        drawer: _MeDrawer(profile: profile),
        appBar: const _MeAppBar(),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              // A soft wash behind the identity card, not a loud fill --
              // the same "colour reads as depth, not decoration" idea as
              // the splash screen's own radial glow, just dialled way down
              // for a screen a student lingers on rather than glances past.
              Positioned(
                top: -60,
                left: 0,
                right: 0,
                height: 280,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.6),
                        radius: 1.1,
                        colors: [
                          context.palette.primary.withValues(alpha: 0.10),
                          context.palette.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _IdentityCard(profile: profile, email: auth?.email, institution: institution),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _StatStrip(
                  cgpa: standing.cgpa,
                  semestersCompleted: record.semesters.length,
                  totalCourses: record.semesters.fold<int>(0, (sum, s) => sum + s.results.length),
                  streak: streak,
                ),
              ),
              const _SectionHeader('Achievements'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _AchievementsGrid(unlocked: achievements, seenAtMount: _seenAtMount),
              ),
              const _SectionHeader('Account', icon: Icons.person_outline),
              _SectionCard(
                children: [
                  _Row(
                    icon: Icons.person_outline,
                    title: 'Profile information',
                    subtitle: 'Name, registration number, department',
                    onTap: () => context.push(Routes.profileSetup, extra: true),
                  ),
                  if (auth?.email != null)
                    _Row(
                      icon: Icons.mail_outline,
                      title: 'Email address',
                      subtitle: auth!.email!,
                      onTap: () => _showEmailInfoSheet(context, auth.email!),
                    ),
                  if (auth?.isGoogleOnly != true)
                    _Row(
                      key: const ValueKey('changePasswordRow'),
                      icon: Icons.lock_outline,
                      title: 'Change password',
                      subtitle: 'Update your account password',
                      onTap: () => _showChangePasswordSheet(context, ref),
                    ),
                ],
              ),
              const _SectionHeader('Academic', icon: Icons.school_outlined),
              _SectionCard(
                children: [
                  _Row(
                    icon: Icons.school_outlined,
                    title: 'Institution',
                    subtitle: institution?.name ?? record.scheme.name,
                    onTap: () => _showInstitutionSheet(context, ref),
                  ),
                  _Row(
                    key: const ValueKey('gradingSchemeRow'),
                    icon: Icons.tune,
                    title: 'Grading scheme',
                    subtitle: '${record.scheme.name} · ${_fmt(record.scheme.maxPoint)} scale',
                    trailingChip: record.scheme.isVerified ? null : 'Unverified',
                    onTap: () => _showGradingSchemeSheet(context, ref),
                  ),
                  _Row(
                    icon: Icons.calendar_month_outlined,
                    title: 'Entry and graduation year',
                    subtitle: profile == null
                        ? 'Not set'
                        : '${profile.entryYear} – ${profile.expectedGraduationYear} · '
                            '${remainingSemestersFromLevel(currentLevel: profile.currentLevel, entryYear: profile.entryYear, expectedGraduationYear: profile.expectedGraduationYear)} semesters left',
                    onTap: profile == null ? null : () => _showYearsSheet(context, ref, profile),
                  ),
                ],
              ),
              const _SectionHeader('App', icon: Icons.settings_outlined),
              _SectionCard(
                children: [
                  _Row(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Reminders, result alerts, streaks',
                    onTap: () => showNotificationSettingsSheet(context),
                  ),
                  _Row(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    subtitle: themeModeLabel(themeMode),
                    onTap: () => showAppearanceSheet(context, ref, themeMode),
                  ),
                  _Row(
                    key: const ValueKey('themeColorRow'),
                    icon: Icons.color_lens_outlined,
                    title: 'Theme colour',
                    subtitle: accent.label,
                    onTap: () => showThemeColorSheet(context, ref, accent),
                  ),
                  _Row(
                    key: const ValueKey('appLockRow'),
                    icon: Icons.lock_outline,
                    title: 'App lock',
                    subtitle: pinState.isSet ? 'PIN enabled' : 'Off',
                    onTap: () => _showAppLockSheet(context, ref, pinState.isSet),
                  ),
                  _Row(
                    icon: Icons.storage_outlined,
                    title: 'Storage',
                    subtitle: '${notesState.notes.length} note${notesState.notes.length == 1 ? '' : 's'}',
                    onTap: () => _showStorageSheet(context, ref),
                  ),
                ],
              ),
              const _SectionHeader('Your data', icon: Icons.folder_outlined),
              _SectionCard(
                children: [
                  _Row(
                    icon: Icons.download_outlined,
                    title: 'Export your data',
                    subtitle: 'Download your results as a file',
                    onTap: () => _exportData(context, ref),
                  ),
                  _Row(
                    icon: Icons.description_outlined,
                    title: 'Privacy policy',
                    subtitle: 'How your data is handled',
                    onTap: () => _showPrivacyPolicySheet(context),
                  ),
                ],
              ),
              _DestructiveSection(record: record, noteCount: notesState.notes.length),
              const _SectionHeader('About', icon: Icons.info_outline),
              _SectionCard(
                children: [
                  _Row(
                    icon: Icons.help_outline,
                    title: 'Help and support',
                    subtitle: 'Frequently asked questions',
                    onTap: () => _showFaqSheet(context),
                  ),
                  _Row(
                    icon: Icons.info_outline,
                    title: 'About ${AppConstants.appName}',
                    subtitle: 'Version · what this app does',
                    onTap: () => _showAboutSheet(context),
                  ),
                ],
              ),
            ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MeAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return TopBarGlassBackground(
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
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.menu, size: 22, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Me',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.palette.bodyText,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Balances the menu square so the title stays centred -- Me has
                // no header bell (see `routes.dart`'s doc on `Routes.notifications`:
                // it's reachable from every tab except this one).
                const SizedBox(width: 44, height: 44),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeDrawer extends StatelessWidget {
  final StudentProfile? profile;

  const _MeDrawer({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.fullName;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                name?.trim().isNotEmpty == true ? name! : AppConstants.appName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.of(context).pop();
                context.go(Routes.home);
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Academics'),
              onTap: () {
                Navigator.of(context).pop();
                context.go(Routes.academics);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final StudentProfile? profile;
  final String? email;
  final Institution? institution;

  const _IdentityCard({required this.profile, required this.email, required this.institution});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.16), context.palette.surface],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.16), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _Avatar(profile: p),
              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: () => context.push(Routes.profileSetup, extra: true),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: Icon(Icons.camera_alt, size: 14, color: context.palette.onPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            p?.fullName.trim().isNotEmpty == true ? p!.fullName : 'Add your profile',
            style: TextStyle(color: context.palette.bodyText, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (p != null) ...[
            const SizedBox(height: 4),
            Text(
              '${p.department.trim().isNotEmpty ? p.department : (institution?.abbreviation ?? 'Independent')} · '
              '${p.currentLevel} ${institution?.levelNoun ?? 'Level'}',
              style: TextStyle(color: context.palette.secondaryText, fontSize: 14.5),
            ),
            const SizedBox(height: 16),
            if (email != null) _ContactRow(icon: Icons.mail_outline, text: email!, accent: accent),
            const SizedBox(height: 8),
            _ContactRow(icon: Icons.badge_outlined, text: p.regNumber, accent: accent),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: () => context.push(Routes.profileSetup, extra: true),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: context.palette.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final StudentProfile? profile;

  const _Avatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final photoPath = profile?.photoPath;
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 6)),
        ],
        image: photoPath != null
            ? DecorationImage(
                image: ResizeImage(
                  FileImage(File(photoPath)),
                  width: (92 * MediaQuery.devicePixelRatioOf(context)).round(),
                ),
                fit: BoxFit.cover,
              )
            : null,
      ),
      // No profile created yet -- a generic "no identity" silhouette reads
      // better here than a literal "?", which looks like an error state
      // rather than an invitation to set one up.
      child: photoPath != null
          ? null
          : profile == null
              ? Icon(Icons.person_outline_rounded, color: accent, size: 40)
              : Text(
                  profile!.initials,
                  style: TextStyle(color: accent, fontSize: 30, fontWeight: FontWeight.w700),
                ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accent;

  const _ContactRow({required this.icon, required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: context.palette.bodyText, fontSize: 14)),
      ],
    );
  }
}

class _StatStrip extends StatelessWidget {
  final double cgpa;
  final int semestersCompleted;
  final int totalCourses;
  final int streak;

  const _StatStrip({
    required this.cgpa,
    required this.semestersCompleted,
    required this.totalCourses,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final cells = [
      (
        icon: Icons.grade_outlined,
        value: cgpa > 0 ? cgpa.toStringAsFixed(2) : '—',
        label: 'CGPA',
        color: cgpa > 0 ? performanceColor(cgpa, normal: accent) : accent,
      ),
      (icon: Icons.event_available_outlined, value: '$semestersCompleted', label: 'Semesters', color: accent),
      (icon: Icons.menu_book_outlined, value: '$totalCourses', label: 'Courses', color: accent),
      (icon: Icons.local_fire_department_outlined, value: '$streak', label: 'Day streak', color: accent),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.palette.bodyText.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final cell in cells)
            Expanded(
              child: Column(
                children: [
                  Icon(cell.icon, size: 20, color: accent),
                  const SizedBox(height: 6),
                  Text(
                    cell.value,
                    style: TextStyle(color: cell.color, fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cell.label,
                    style: TextStyle(color: context.palette.secondaryText, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _SectionHeader(this.label, {this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: context.palette.primary),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: TextStyle(color: context.palette.bodyText, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.palette.bodyText.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 72, color: context.palette.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingChip;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _Row({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingChip,
    this.iconColor,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 21, color: accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor ?? context.palette.bodyText,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.palette.secondaryText, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (trailingChip != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.palette.amber.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trailingChip!,
                    style: TextStyle(
                      color: context.palette.amber,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (onTap != null)
                const Icon(Icons.chevron_right, size: 22, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  final Map<BadgeId, DateTime> unlocked;
  final Set<BadgeId> seenAtMount;

  const _AchievementsGrid({required this.unlocked, required this.seenAtMount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
      ),
      child: Row(
        children: [
          for (final badge in allBadges)
            Expanded(
              child: _AchievementCell(
                badge: badge,
                isUnlocked: unlocked.containsKey(badge.id),
                justUnlocked: unlocked.containsKey(badge.id) && !seenAtMount.contains(badge.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _AchievementCell extends StatelessWidget {
  final BadgeDefinition badge;
  final bool isUnlocked;
  final bool justUnlocked;

  const _AchievementCell({required this.badge, required this.isUnlocked, required this.justUnlocked});

  @override
  Widget build(BuildContext context) {
    final appearance = _badgeAppearance(context, badge.id);
    return Column(
      children: [
        BadgeShield(
          color: appearance.color,
          icon: appearance.icon,
          unlocked: isUnlocked,
          justUnlocked: justUnlocked,
        ),
        const SizedBox(height: 8),
        Text(
          badge.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            color: context.palette.bodyText,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          badge.criteria,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(color: context.palette.secondaryText, fontSize: 10.5),
        ),
      ],
    );
  }
}

// ============================================================ Account ====

void _showEmailInfoSheet(BuildContext context, String email) {
  _showSheet(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetTitle(context, 'Email address'),
        const SizedBox(height: 8),
        Text(email, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text(
          "Your email is tied to your account and can't be changed from here yet.",
          style: TextStyle(color: context.palette.secondaryText, fontSize: 14),
        ),
      ],
    ),
  );
}

void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
      ),
      child: _ChangePasswordForm(ref: ref),
    ),
  );
}

class _ChangePasswordForm extends StatefulWidget {
  final WidgetRef ref;

  const _ChangePasswordForm({required this.ref});

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;
  bool _newObscured = true;
  bool _confirmObscured = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _newController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  int get _strength {
    final p = _newController.text;
    if (p.isEmpty) return 0;
    var score = 0;
    if (p.length >= 8) score++;
    if (p.length >= 12) score++;
    if (RegExp(r'[0-9]').hasMatch(p) && RegExp(r'[A-Za-z]').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score.clamp(0, 4);
  }

  ({String label, Color color}) get _strengthLabel => switch (_strength) {
        0 => (label: 'Too short', color: const Color(0xFF9CA3AF)),
        1 => (label: 'Weak', color: const Color(0xFFDC2626)),
        2 => (label: 'Fair', color: const Color(0xFFB45309)),
        3 => (label: 'Good', color: const Color(0xFF16A34A)),
        _ => (label: 'Strong', color: const Color(0xFF15803D)),
      };

  Future<void> _submit() async {
    final newPassword = _newController.text;
    if (newPassword.length < 8) {
      setState(() => _error = 'Password needs at least 8 characters.');
      return;
    }
    if (newPassword != _confirmController.text) {
      setState(() => _error = "Passwords don't match.");
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.ref.read(authStateProvider.notifier).changePassword(newPassword);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = authErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.primary;
    final hasPassword = _newController.text.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(Icons.lock_reset_rounded, color: accent, size: 28),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: _sheetTitle(context, 'Change password')),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Use at least 8 characters, with a mix of letters, numbers and symbols.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.secondaryText, fontSize: 13.5),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _newController,
          obscureText: _newObscured,
          decoration: InputDecoration(
            labelText: 'New password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_newObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              onPressed: () => setState(() => _newObscured = !_newObscured),
            ),
            filled: true,
            fillColor: context.palette.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        if (hasPassword) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _strength / 4,
                    minHeight: 5,
                    backgroundColor: context.palette.divider,
                    valueColor: AlwaysStoppedAnimation(_strengthLabel.color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _strengthLabel.label,
                style: TextStyle(color: _strengthLabel.color, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _confirmController,
          obscureText: _confirmObscured,
          decoration: InputDecoration(
            labelText: 'Confirm new password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_confirmObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              onPressed: () => setState(() => _confirmObscured = !_confirmObscured),
            ),
            filled: true,
            fillColor: context.palette.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.palette.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: context.palette.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!, style: TextStyle(color: context.palette.error, fontSize: 13.5)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            key: const ValueKey('submitPasswordChangeTap'),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: context.palette.onPrimary),
                  )
                : const Text('Update password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// =========================================================== Academic ====

void _showInstitutionSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.75),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetTitle(context, 'Institution'),
              const SizedBox(height: 6),
              Text(
                "Changing your institution recalculates your CGPA under a different scheme.",
                style: TextStyle(color: context.palette.amber, fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: nigerianInstitutions.length,
                  itemBuilder: (context, index) {
                    final institution = nigerianInstitutions[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(institution.name),
                      subtitle: Text(institution.abbreviation),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _confirmInstitutionChange(context, ref, institution);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _confirmInstitutionChange(BuildContext context, WidgetRef ref, Institution institution) {
  final record = ref.read(academicRecordProvider);
  final newScheme = defaultSchemes[institution.id] ?? fallbackScheme;
  final previous = CgpaEngine.computeStanding(semesters: record.semesters, scheme: record.scheme);
  final result = CgpaEngine.recalculate(
    semesters: record.semesters,
    scheme: newScheme,
    previous: previous,
  );

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Switch institution?'),
      content: Text(
        'Your CGPA under ${institution.name}\'s scheme would be ${_fmt(result.updated.cgpa)} '
        '(currently ${_fmt(result.previous.cgpa)}).',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
        FilledButton(
          key: const ValueKey('confirmInstitutionChangeTap'),
          onPressed: () {
            Navigator.of(dialogContext).pop();
            ref.read(academicRecordProvider.notifier).updateScheme(newScheme);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('CGPA ${_fmt(result.previous.cgpa)} → ${_fmt(result.updated.cgpa)}')),
            );
          },
          child: const Text('Switch'),
        ),
      ],
    ),
  );
}

void _showGradingSchemeSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => _GradingSchemeSheet(ref: ref),
  );
}

const _repeatPolicyLabel = <RepeatPolicy, String>{
  RepeatPolicy.countBothAttempts: 'Both attempts count toward your CGPA',
  RepeatPolicy.replaceOriginal: 'Your retake replaces the original grade',
  RepeatPolicy.replaceWithCap: 'Your retake replaces the original, capped at a maximum',
};

const _aggregationLabel = <CgpaAggregationMode, String>{
  CgpaAggregationMode.creditWeighted: 'Standard (credit-unit weighted)',
  CgpaAggregationMode.recursiveSemesterAverage: 'Running average (CGPA + new GPA) ÷ 2',
};

class _GradingSchemeSheet extends StatefulWidget {
  final WidgetRef ref;

  const _GradingSchemeSheet({required this.ref});

  @override
  State<_GradingSchemeSheet> createState() => _GradingSchemeSheetState();
}

class _GradingSchemeSheetState extends State<_GradingSchemeSheet> {
  late RepeatPolicy _policy;
  late double _capPoint;
  late CgpaAggregationMode _aggregation;

  GradingScheme get _originalScheme => widget.ref.read(academicRecordProvider).scheme;

  @override
  void initState() {
    super.initState();
    _policy = _originalScheme.repeatPolicy;
    _capPoint = _originalScheme.repeatCapPoint ?? 3.0;
    _aggregation = _originalScheme.cgpaAggregation;
  }

  bool get _dirty =>
      _policy != _originalScheme.repeatPolicy ||
      (_policy == RepeatPolicy.replaceWithCap && _capPoint != (_originalScheme.repeatCapPoint ?? 3.0)) ||
      _aggregation != _originalScheme.cgpaAggregation;

  void _save() {
    final scheme = _originalScheme;
    final newScheme = scheme.copyWith(
      repeatPolicy: _policy,
      repeatCapPoint: _policy == RepeatPolicy.replaceWithCap ? _capPoint : scheme.repeatCapPoint,
      cgpaAggregation: _aggregation,
    );
    final record = widget.ref.read(academicRecordProvider);
    final previous = CgpaEngine.computeStanding(semesters: record.semesters, scheme: scheme);
    final result = CgpaEngine.recalculate(
      semesters: record.semesters,
      scheme: newScheme,
      previous: previous,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change grading policy?'),
        content: Text(
          'This changes how your results combine into a CGPA. It will be recalculated.\n\n'
          'CGPA: ${_fmt(result.previous.cgpa)} → ${_fmt(result.updated.cgpa)}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            key: const ValueKey('confirmPolicyChangeTap'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.ref.read(academicRecordProvider.notifier).updateScheme(newScheme);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('CGPA ${_fmt(result.previous.cgpa)} → ${_fmt(result.updated.cgpa)}')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _originalScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetTitle(context, 'Grading scheme'),
              const SizedBox(height: 4),
              Text(scheme.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(
                'Max point ${_fmt(scheme.maxPoint)}',
                style: TextStyle(color: context.palette.secondaryText, fontSize: 14),
              ),
              if (!scheme.isVerified) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.palette.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "This grading scheme hasn't been confirmed against the official policy yet.",
                    style: TextStyle(color: context.palette.amber, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text('Grade points', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                scheme.grades.map((g) => '${g.letter} ${g.point.toStringAsFixed(1)} (${g.minScore}–${g.maxScore})').join('  ·  '),
                style: TextStyle(color: context.palette.secondaryText, fontSize: 13.5),
              ),
              const SizedBox(height: 16),
              const Text('Classification bands', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                scheme.classifications
                    .map((c) => '${c.shortLabel} ${_fmt(c.minCgpa)}–${_fmt(c.maxCgpa)}')
                    .join('  ·  '),
                style: TextStyle(color: context.palette.secondaryText, fontSize: 13.5),
              ),
              const SizedBox(height: 20),
              const Text('Repeat / carryover policy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              for (final policy in RepeatPolicy.values)
                RadioListTile<RepeatPolicy>(
                  key: ValueKey('repeatPolicy_${policy.name}'),
                  contentPadding: EdgeInsets.zero,
                  value: policy,
                  groupValue: _policy,
                  title: Text(_repeatPolicyLabel[policy]!, style: const TextStyle(fontSize: 14.5)),
                  onChanged: (v) => setState(() => _policy = v!),
                ),
              if (_policy == RepeatPolicy.replaceWithCap) ...[
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('repeatCapPointField'),
                  initialValue: _capPoint.toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Cap point'),
                  onChanged: (v) => setState(() => _capPoint = double.tryParse(v) ?? _capPoint),
                ),
              ],
              const SizedBox(height: 20),
              const Text('CGPA calculation method', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Text(
                'The standard method is credit-unit weighted and matches an actual transcript. '
                'Only switch this if your institution has specifically confirmed otherwise.',
                style: TextStyle(color: context.palette.secondaryText, fontSize: 12.5),
              ),
              for (final mode in CgpaAggregationMode.values)
                RadioListTile<CgpaAggregationMode>(
                  key: ValueKey('cgpaAggregation_${mode.name}'),
                  contentPadding: EdgeInsets.zero,
                  value: mode,
                  groupValue: _aggregation,
                  title: Text(_aggregationLabel[mode]!, style: const TextStyle(fontSize: 14.5)),
                  onChanged: (v) => setState(() => _aggregation = v!),
                ),
              if (_aggregation == CgpaAggregationMode.recursiveSemesterAverage) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.palette.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Under this method, your CGPA after each semester is a straight average of your '
                    "previous CGPA and that semester's GPA -- it ignores credit units entirely, so it "
                    'can resolve the same results to a different classification than the standard '
                    'method. You can switch back to Standard here at any time.',
                    style: TextStyle(color: context.palette.amber, fontSize: 12.5),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  key: const ValueKey('saveGradingSchemeTap'),
                  onPressed: _dirty ? _save : null,
                  child: const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showYearsSheet(BuildContext context, WidgetRef ref, StudentProfile profile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => _YearsForm(ref: ref, profile: profile),
  );
}

class _YearsForm extends StatefulWidget {
  final WidgetRef ref;
  final StudentProfile profile;

  const _YearsForm({required this.ref, required this.profile});

  @override
  State<_YearsForm> createState() => _YearsFormState();
}

class _YearsFormState extends State<_YearsForm> {
  late int _entryYear = widget.profile.entryYear;
  late int _gradYear = widget.profile.expectedGraduationYear;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    final entryOptions = {for (var y = now - 10; y <= now + 1; y++) y, _entryYear}.toList()..sort();
    final gradOptions = {for (var y = _entryYear; y <= _entryYear + 8; y++) y, _gradYear}.toList()..sort();
    final remaining = remainingSemestersFromLevel(
      currentLevel: widget.profile.currentLevel,
      entryYear: _entryYear,
      expectedGraduationYear: _gradYear,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle(context, 'Entry and graduation year'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _entryYear,
                  decoration: const InputDecoration(labelText: 'Entry year'),
                  items: [for (final y in entryOptions) DropdownMenuItem(value: y, child: Text('$y'))],
                  onChanged: (v) => setState(() {
                    _entryYear = v!;
                    if (_gradYear < _entryYear) _gradYear = _entryYear;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: gradOptions.contains(_gradYear) ? _gradYear : gradOptions.first,
                  decoration: const InputDecoration(labelText: 'Expected graduation'),
                  items: [for (final y in gradOptions) DropdownMenuItem(value: y, child: Text('$y'))],
                  onChanged: (v) => setState(() => _gradYear = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "That's $remaining semester${remaining == 1 ? '' : 's'} remaining.",
            style: TextStyle(color: context.palette.secondaryText, fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const ValueKey('saveYearsTap'),
              onPressed: () async {
                await widget.ref.read(studentProfileProvider.notifier).save(
                      widget.profile.copyWith(entryYear: _entryYear, expectedGraduationYear: _gradYear),
                    );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$remaining semesters remaining, recalculated.')),
                );
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================ App ====

void _showAppLockSheet(BuildContext context, WidgetRef ref, bool isSet) {
  if (!isSet) {
    showPinSetupSheet(context);
    return;
  }
  showModalBottomSheet(
    context: context,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            key: const ValueKey('changePinTap'),
            leading: const Icon(Icons.password_outlined),
            title: const Text('Change PIN'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _verifyPinThenAct(context, ref, onVerified: () async => showPinSetupSheet(context));
            },
          ),
          Divider(height: 1, color: context.palette.divider),
          Consumer(
            // Named `_`/`localRef` deliberately, NOT `context`/`ref` --
            // shadowing the outer `_showAppLockSheet(BuildContext context,
            // WidgetRef ref, ...)` parameters with THIS Consumer's own was
            // the bug, and it bit twice: the first fix caught `context`
            // (used for `Navigator`/`showSecurityQuestionsSetupSheet`) but
            // missed that `ref` has the exact same problem -- a Consumer's
            // `WidgetRef` is just as tied to its own element's lifecycle as
            // its `BuildContext` is. `Navigator.of(sheetContext).pop()`
            // below closes this whole sheet (and this Consumer) immediately
            // on tap; by the time the PIN pad's `onComplete` callback fires
            // seconds later and calls `ref.read(pinProvider.notifier)
            // .verify(pin)`, that `ref` belonged to an already-disposed
            // element, which Riverpod rejects -- the thrown error was never
            // caught, so the PIN pad just sat there looking like nothing
            // happened, the exact symptom reported. `localRef` below is
            // still correct to use for the reactive `.watch` that makes
            // this row's label update live; only the long-lived outer
            // `context`/`ref` (the Me tab screen itself, which stays
            // mounted) may cross into the `onTap` closure.
            builder: (_, localRef, __) {
              final hasQuestions = localRef.watch(securityQuestionsProvider.select((s) => s.hasQuestions));
              return ListTile(
                key: const ValueKey('securityQuestionsTap'),
                leading: const Icon(Icons.quiz_outlined),
                title: Text(hasQuestions ? 'Security questions' : 'Set up security questions'),
                subtitle: const Text("Recovers your PIN if it's forgotten"),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _verifyPinThenAct(
                    context,
                    ref,
                    onVerified: () async => showSecurityQuestionsSetupSheet(context),
                  );
                },
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final pinState = ref.watch(pinProvider);
              if (!pinState.biometricAvailable) return const SizedBox.shrink();
              return Column(
                children: [
                  Divider(height: 1, color: context.palette.divider),
                  SwitchListTile(
                    key: const ValueKey('biometricToggle'),
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('Unlock with fingerprint'),
                    subtitle: const Text('Offered alongside your PIN, never instead of it'),
                    value: pinState.biometricEnabled,
                    onChanged: (enabled) => ref.read(pinProvider.notifier).setBiometricEnabled(enabled),
                  ),
                ],
              );
            },
          ),
          Divider(height: 1, color: context.palette.divider),
          Consumer(
            builder: (context, ref, _) {
              final autoLockMinutes = ref.watch(pinProvider.select((s) => s.autoLockMinutes));
              return ListTile(
                key: const ValueKey('autoLockRow'),
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Lock after'),
                subtitle: Text('${_autoLockLabel(autoLockMinutes)} in the background'),
                onTap: () => _showAutoLockPicker(context, ref, autoLockMinutes),
              );
            },
          ),
          Divider(height: 1, color: context.palette.divider),
          ListTile(
            key: const ValueKey('turnOffPinTap'),
            leading: Icon(Icons.lock_open_outlined, color: context.palette.error),
            title: Text('Turn off PIN lock', style: TextStyle(color: context.palette.error)),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _verifyPinThenAct(
                context,
                ref,
                onVerified: () async {
                  await ref.read(pinProvider.notifier).clearPin();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN lock turned off.')),
                    );
                  }
                },
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

const _autoLockOptions = [1, 5, 10, 15, 30, 60];

String _autoLockLabel(int minutes) => minutes == 60 ? '1 hour' : '$minutes minute${minutes == 1 ? '' : 's'}';

void _showAutoLockPicker(BuildContext context, WidgetRef ref, int current) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _sheetTitle(context, 'Lock after'),
          const SizedBox(height: 4),
          for (final minutes in _autoLockOptions)
            ListTile(
              key: ValueKey('autoLockOption_$minutes'),
              title: Text(_autoLockLabel(minutes)),
              trailing: minutes == current ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
              onTap: () {
                ref.read(pinProvider.notifier).setAutoLockMinutes(minutes);
                Navigator.of(sheetContext).pop();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Requires the CURRENT PIN before changing or removing it -- otherwise
/// anyone holding an already-unlocked phone (the exact scenario the PIN
/// exists to guard against) could disable the lock permanently without
/// ever knowing the code.
void _verifyPinThenAct(BuildContext context, WidgetRef ref, {required Future<void> Function() onVerified}) {
  final controller = PinPadController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) {
      var wrong = false;
      return StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetTitle(context, 'Enter your current PIN'),
              if (wrong) ...[
                const SizedBox(height: 8),
                Text('Incorrect PIN.', style: TextStyle(color: context.palette.error, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              PinPad(
                controller: controller,
                onComplete: (pin) async {
                  final ok = await ref.read(pinProvider.notifier).verify(pin);
                  if (ok) {
                    if (context.mounted) Navigator.of(context).pop();
                    await onVerified();
                  } else {
                    controller.clear();
                    setState(() => wrong = true);
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}


void _showStorageSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => _StorageSheet(ref: ref),
  );
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _StorageSheet extends ConsumerWidget {
  final WidgetRef ref;

  const _StorageSheet({required this.ref});

  Future<int> _sizeOf(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return 0;
      return await file.length();
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider).notes;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetTitle(context, 'Storage'),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return FutureBuilder<int>(
                      future: _sizeOf(note.filePath),
                      builder: (context, snapshot) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(note.title),
                        subtitle: Text(_formatBytes(snapshot.data ?? 0)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                          onPressed: () => ref.read(notesProvider.notifier).deleteNote(note.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (notes.isEmpty)
                Text(
                  'No notes uploaded yet.',
                  style: TextStyle(color: context.palette.secondaryText, fontSize: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================================== Your data ====

Future<void> _exportData(BuildContext context, WidgetRef ref) async {
  final profile = ref.read(studentProfileProvider);
  final record = ref.read(academicRecordProvider);
  final notesState = ref.read(notesProvider);
  final goal = ref.read(goalProvider);

  final payload = buildExportPayload(
    profile: profile,
    record: record,
    notes: notesState.notes,
    pagesReadByNote: notesState.pagesReadByNote,
    goal: goal,
  );

  final messenger = ScaffoldMessenger.of(context);
  // Writing the file and opening the system share sheet both take a beat --
  // with no feedback until then, a tap can read as "nothing happened" on a
  // slower device. This fires before any of that `await`s, so the student
  // always sees something the instant they tap.
  messenger.showSnackBar(
    const SnackBar(content: Text('Preparing your export…'), duration: Duration(seconds: 2)),
  );
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/perform_plus_export.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    final result = await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Perform+ data export'),
    );
    if (!context.mounted) return;
    // `ShareResultStatus.unavailable` on Android just means this build
    // can't track which target the student picked (`withResult` isn't
    // set) -- the chooser still opened fine, so it's treated as success,
    // never a silent no-op: either way the student sees a concrete result.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.status == ShareResultStatus.dismissed
              ? 'Export cancelled.'
              : 'Export ready -- choose where to save or send it.',
        ),
      ),
    );
  } catch (error, stackTrace) {
    // Never surfaced further than this device's own console today (Sentry
    // is inert until SENTRY_DSN is set -- see main.dart) but a swallowed,
    // unlogged exception here left this failure completely undiagnosable
    // the one time it actually mattered.
    debugPrint('Export failed: $error\n$stackTrace');
    if (context.mounted) {
      messenger.showSnackBar(const SnackBar(content: Text("Couldn't export your data")));
    }
  }
}

void _showPrivacyPolicySheet(BuildContext context) {
  _showSheet(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetTitle(context, 'Privacy policy'),
        const SizedBox(height: 12),
        Text(
          "${AppConstants.appName} doesn't have a hosted privacy policy yet -- TODO(v1) before release. "
          'For now: your results, notes and photo are stored on this device. Your name and email leave '
          "this device only through your Supabase account; nothing else is uploaded.",
          style: TextStyle(color: context.palette.secondaryText, fontSize: 14, height: 1.5),
        ),
      ],
    ),
  );
}

// ========================================================= Destructive ====

class _DestructiveSection extends StatelessWidget {
  final AcademicRecord record;
  final int noteCount;

  const _DestructiveSection({required this.record, required this.noteCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.30), width: 1.5),
      ),
      child: Consumer(
        builder: (context, ref, _) => Column(
          children: [
            _Row(
              icon: Icons.logout,
              title: 'Sign out',
              subtitle: 'Your results stay on this device',
              iconColor: const Color(0xFFDC2626),
              titleColor: const Color(0xFFDC2626),
              onTap: () => confirmSignOut(context, ref, record: record, noteCount: noteCount),
            ),
            Divider(height: 1, indent: 72, color: context.palette.divider),
            _Row(
              key: const ValueKey('deleteAccountRow'),
              icon: Icons.delete_forever_outlined,
              title: 'Delete account',
              subtitle: 'Permanently remove your account and data',
              iconColor: const Color(0xFFDC2626),
              titleColor: const Color(0xFFDC2626),
              onTap: () => _showDeleteAccountDialog(context, ref, record: record, noteCount: noteCount),
            ),
          ],
        ),
      ),
    );
  }
}

void _showDeleteAccountDialog(
  BuildContext context,
  WidgetRef ref, {
  required AcademicRecord record,
  required int noteCount,
}) {
  final semesterCount = record.semesters.length;
  final resultCount = record.semesters.fold<int>(0, (sum, s) => sum + s.results.length);
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final canDelete = controller.text.trim() == 'DELETE';
        return AlertDialog(
          title: const Text('Delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This removes $semesterCount semester${semesterCount == 1 ? '' : 's'}, '
                '$resultCount result${resultCount == 1 ? '' : 's'}, '
                '$noteCount note${noteCount == 1 ? '' : 's'} and your account. '
                "It cannot be undone.",
              ),
              const SizedBox(height: 8),
              Text(
                "We can't yet remove your account from our servers automatically -- contact support "
                'to finish that step. This deletes everything on this device now and signs you out.',
                style: TextStyle(color: context.palette.secondaryText, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _exportData(context, ref);
                },
                child: const Text('Export your data first'),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('deleteAccountConfirmField'),
                controller: controller,
                decoration: const InputDecoration(labelText: 'Type DELETE to confirm'),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(
              key: const ValueKey('deleteAccountConfirmTap'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: canDelete
                  ? () async {
                      Navigator.of(dialogContext).pop();
                      await ref.read(appDatabaseProvider).wipeLocalData(AppConstants.localProfileId);
                      await ref.read(authStateProvider.notifier).signOut();
                      if (context.mounted) context.go(Routes.splash);
                    }
                  : null,
              child: const Text('Delete account'),
            ),
          ],
        );
      },
    ),
  );
}

// =============================================================== About ====

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem(this.question, this.answer);
}

const _faqItems = <_FaqItem>[
  _FaqItem(
    'How is my CGPA actually calculated?',
    'Every course result is turned into quality points (grade point × credit unit) under your '
        "institution's grading scheme, then summed and divided by total credit units. You can see the "
        "exact breakdown for any semester from its detail sheet on the Academics tab -- nothing is "
        'estimated.',
  ),
  _FaqItem(
    "What if my repeat/carryover policy looks wrong?",
    "Every seeded grading scheme except FUTO's is unverified -- a reasonable default, not a confirmed "
        "policy. Open Grading scheme above to see and correct how repeated courses count; changing it "
        'shows you the exact CGPA before and after.',
  ),
  _FaqItem(
    'Why did my CGPA change after I added a new result?',
    'Adding or editing any semester recalculates your whole record from scratch, since an early grade '
        "correction can shift every later semester's running CGPA. You'll always see a before/after "
        'delta with an Undo when this happens.',
  ),
  _FaqItem(
    'Does my data leave this device?',
    'Your results, notes and photo stay on this device. Only your name and email are synced to your '
        'account when you sign in -- nothing else is uploaded anywhere.',
  ),
  _FaqItem(
    'How do I set or change my target classification?',
    "Open the Home tab and tap your goal ring, or Set a goal if you haven't picked one yet. Every "
        'required-average figure is solved from your actual record, never a flat threshold.',
  ),
  _FaqItem(
    "My institution isn't listed, or its scheme looks off",
    'Pick the closest match from Institution above, or Other during setup, then correct the grading '
        'scheme directly -- an unverified scheme is flagged with an amber chip so you know to double-check '
        'it against your department.',
  ),
];

void _showFaqSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetTitle(context, 'Help and support'),
              const SizedBox(height: 4),
              Text(
                'Frequently asked questions',
                style: TextStyle(color: context.palette.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _faqItems.length; i++) ...[
                if (i > 0) Divider(height: 24, color: context.palette.divider),
                Text(
                  _faqItems[i].question,
                  style: TextStyle(color: context.palette.bodyText, fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _faqItems[i].answer,
                  style: TextStyle(color: context.palette.secondaryText, fontSize: 14, height: 1.5),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Still stuck?",
                      style: TextStyle(color: context.palette.bodyText, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "For anything specific to your own numbers, ask the Advisor -- it can walk through "
                      'your actual record.',
                      style: TextStyle(color: context.palette.secondaryText, fontSize: 13.5),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('faqAskAdvisorTap'),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          GoRouter.of(context).go(Routes.ai);
                        },
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Ask the Advisor'),
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
  );
}

void _showAboutSheet(BuildContext context) {
  _showSheet(
    context,
    FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? AppConstants.version;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetTitle(context, 'About ${AppConstants.appName}'),
            const SizedBox(height: 4),
            Text(
              'Version $version',
              style: TextStyle(color: context.palette.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Text(
              '${AppConstants.appName} helps Nigerian university students track their CGPA, understand '
              'exactly how it was calculated, and plan realistically toward a target classification.',
              style: TextStyle(color: context.palette.bodyText, fontSize: 14.5, height: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              "Every number you see is computed from your own results under your institution's grading "
              'scheme -- never estimated, never guessed, and never left to an AI model to calculate.',
              style: TextStyle(color: context.palette.secondaryText, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 14),
            Text(
              AppConstants.tagline,
              style: TextStyle(color: context.palette.secondaryText, fontSize: 13.5, fontStyle: FontStyle.italic),
            ),
          ],
        );
      },
    ),
  );
}

// ============================================================== Shared ====

Future<void> _showSheet(BuildContext context, Widget child) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(padding: const EdgeInsets.all(24), child: child),
    );

Widget _sheetTitle(BuildContext context, String text) => Text(
      text,
      style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
    );

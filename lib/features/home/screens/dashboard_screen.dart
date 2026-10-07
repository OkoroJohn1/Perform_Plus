/// Dashboard — the Home tab, and the screen students return to most.
///
/// Every number comes from [CgpaEngine]/[ProjectionSolver], read through
/// [standingProvider]/[targetProjectionProvider]/[goalProvider] — nothing is
/// computed in this widget layer, nothing is invented. Three states:
///   * empty   — no results at all.
///   * partial — one semester. A single point can't draw a trend, so the
///     chart is swapped for a placeholder and the credit split is hidden.
///   * full    — two or more semesters (credit split needs three).
///
/// This is the one screen with its own tinted `#F7F7FB` scaffold — see
/// [DashboardPalette] — rather than the app's permanent dark gradient or
/// the onboarding flat white, so white cards lift off it. It still lives
/// inside the shared [AppScaffold]'s bottom nav; the flat surface here is
/// its own nested `Scaffold` so it can also own a drawer.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/repositories/goal_provider.dart';
import '../../../data/repositories/notification_provider.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/glass_top_bar.dart';
import '../../auth/providers/pin_provider.dart';
import '../../auth/providers/profile_provider.dart';
import '../../auth/providers/security_questions_provider.dart';
import '../../auth/screens/pin_prompt_dialog.dart';
import '../../auth/screens/security_questions_prompt_dialog.dart';
import '../../academics/widgets/add_semester_sheet.dart';
import '../widgets/cgpa_card.dart';
import '../widgets/credit_load_split_card.dart';
import '../widgets/next_action_card.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/required_pace_strip.dart';
import '../widgets/semester_comparison_card.dart';
import '../widgets/trend_3d_chart.dart';
import '../widgets/trend_chart.dart';
import 'notifications_panel.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _pinPromptQueued = false;
  bool _securityQuestionsPromptQueued = false;

  void _maybeQueuePinPrompt(PinState pinState) {
    if (_pinPromptQueued || !pinState.loaded || pinState.isSet || pinState.promptDismissed) {
      return;
    }
    _pinPromptQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showPinPromptDialog(context, ref);
    });
  }

  /// Only offered once a PIN already exists -- recovery questions for a PIN
  /// that doesn't exist yet makes no sense, and `showPinPromptDialog` above
  /// already owns that first step.
  void _maybeQueueSecurityQuestionsPrompt(PinState pinState, SecurityQuestionsState sqState) {
    if (_securityQuestionsPromptQueued ||
        !pinState.loaded ||
        !pinState.isSet ||
        !sqState.loaded ||
        sqState.hasQuestions ||
        sqState.promptDismissed) {
      return;
    }
    _securityQuestionsPromptQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showSecurityQuestionsPromptDialog(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final standing = ref.watch(standingProvider);
    final profile = ref.watch(studentProfileProvider);
    final pinState = ref.watch(pinProvider);
    _maybeQueuePinPrompt(pinState);
    _maybeQueueSecurityQuestionsPrompt(pinState, ref.watch(securityQuestionsProvider));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: context.palette.background,
        drawer: AppDrawer(profile: profile),
        appBar: const _DashboardAppBar(),
        body: SafeArea(
          top: false,
          child: standing.hasData
              ? _PopulatedDashboard(standing: standing, profile: profile)
              : const _EmptyDashboard(),
        ),
      ),
    );
  }
}

class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DashboardAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return TopBarGlassBackground(
      // `SafeArea` here, not just a fixed `height: 64` -- this is a raw
      // custom `PreferredSizeWidget`, not the real Material `AppBar` (which
      // does this same push-down internally), so without it the top of
      // this bar renders under the status bar overlay instead of below it.
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
                    'Dashboard',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.palette.bodyText,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const _ScanResultSlipButton(),
                const _NotificationBell(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashboard entry point for the on-device result-slip scanner -- this
/// app uses modal sheets rather than pushed routes for "add a semester"
/// (see `routes.dart`: only the five tabs and notifications are actual
/// routes), so "reachable from the dashboard" means opening the same
/// sheet Academics/Backfill already use, not a new standalone screen.
class _ScanResultSlipButton extends StatelessWidget {
  const _ScanResultSlipButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        key: const ValueKey('dashboardScanResultSlipTap'),
        icon: const Icon(Icons.document_scanner_outlined, size: 22, color: Color(0xFF4B5563)),
        tooltip: 'Scan result slip',
        onPressed: () => showAddSemesterSheet(context),
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

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insights_outlined, size: 44, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              'Add your first semester to see your dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.secondaryText, fontSize: 16),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go(Routes.academics),
              child: const Text('Add results'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopulatedDashboard extends ConsumerWidget {
  final AcademicStanding standing;
  final StudentProfile? profile;

  const _PopulatedDashboard({required this.standing, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(academicRecordProvider);
    final scheme = record.scheme;
    final rawSemesters = record.semesters;
    final goalTarget = ref.watch(goalProvider);
    final goal = ref.watch(targetProjectionProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(academicRecordProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          _GreetingRow(profile: profile),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              CgpaCard(
                standing: standing,
                scheme: scheme,
                goal: goal,
                goalBand: goalTarget?.band,
                onSetGoal: () => context.go(Routes.goalSetting),
              ),
              Positioned(
                left: 28,
                right: 28,
                // Was -34 -- too shallow an overlap: when the hero card's
                // content ran a bit taller (e.g. the "Below 3.50" badge
                // showing), the classification label sat low enough in the
                // card to collide with this bar's own icons/numbers instead
                // of just touching the gradient's empty margin below it.
                bottom: -54,
                child: QuickStatsRow(standing: standing, rawSemesters: rawSemesters),
              ),
            ],
          ),
          // Room for the stats bar floating below the hero card's bottom
          // edge (see the Stack above, now -54) plus normal breathing space.
          const SizedBox(height: 74),
          if (goal != null &&
              goal.feasibility.name != 'secured' &&
              goal.requiredAverage != null) ...[
            RequiredPaceStrip(goal: goal, bandShortLabel: goalTarget?.band.shortLabel ?? ''),
            const SizedBox(height: 12),
          ],
          TrendCard(standing: standing, scheme: scheme, rawSemesters: rawSemesters, goal: goal),
          const SizedBox(height: 20),
          Trend3DChart(standing: standing, scheme: scheme),
          const SizedBox(height: 20),
          SemesterComparisonCard(standing: standing, scheme: scheme),
          const SizedBox(height: 20),
          CreditLoadSplitCard(standing: standing, rawSemesters: rawSemesters),
          const SizedBox(height: 20),
          NextActionCard(
            standing: standing,
            rawSemesters: rawSemesters,
            scheme: scheme,
            profile: profile,
            goal: goal,
            onTap: () => context.go(Routes.academics),
          ),
        ],
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  final StudentProfile? profile;

  const _GreetingRow({required this.profile});

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _firstName(String? fullName) {
    if (fullName == null) return 'there';
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'there' : parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final name = profile?.fullName;
    final photoPath = profile?.photoPath;
    final initials = profile?.initials;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${_greeting()}, ',
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: _firstName(name),
                    style: TextStyle(
                      color: context.palette.bodyText,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go(Routes.me),
            child: _Avatar(photoPath: photoPath, initials: initials),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoPath;
  final String? initials;

  const _Avatar({required this.photoPath, required this.initials});

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    if (path != null) {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: context.palette.bodyText.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          image: DecorationImage(
            image: ResizeImage(FileImage(File(path)), width: (54 * MediaQuery.devicePixelRatioOf(context)).round()),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final accent = context.palette.primary;
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      // No profile created yet -- a generic "no identity" silhouette reads
      // better here than a literal "?", which looks like an error state
      // rather than an invitation to set one up.
      child: initials == null
          ? Icon(Icons.person_outline_rounded, color: accent, size: 26)
          : Text(
              initials!,
              style: TextStyle(
                color: accent,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

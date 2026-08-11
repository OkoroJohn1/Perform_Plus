/// Application routing.
///
/// The route table encodes the Act 1 / Act 2 / Act 3 structure directly:
/// everything under `/onboarding` is reachable WITHOUT authentication, so a
/// student can compute a GPA before they are asked to create an account.
/// Time-to-value is the conversion lever; the signup gate sits after the
/// payoff, not before it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/academics/screens/academics_shell.dart';
import '../../features/ai/screens/ai_shell.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/home/screens/dashboard_screen.dart';
import '../../features/me/screens/me_shell.dart';
import '../../features/onboarding/screens/add_first_results_screen.dart';
import '../../features/onboarding/screens/backfill_screen.dart';
import '../../features/onboarding/screens/goal_setting_screen.dart';
import '../../features/onboarding/screens/gpa_reveal_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/study/screens/study_shell.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,

    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Act 1 is deliberately open. No redirect logic applies here.
      if (Routes.isPreAuth(loc)) return null;

      final signedIn = auth.valueOrNull?.isSignedIn ?? false;
      if (!signedIn) return Routes.signIn;

      // Signed in but profile incomplete — the engine needs entry year and
      // expected graduation year to count remaining semesters.
      final profileComplete = auth.valueOrNull?.profileComplete ?? false;
      if (!profileComplete && loc != Routes.profileSetup) {
        return Routes.profileSetup;
      }

      return null;
    },

    routes: [
      // ---- Act 1: pre-account, no login required -------------------------
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.addFirstResults,
        builder: (_, __) => const AddFirstResultsScreen(),
      ),
      GoRoute(
        path: Routes.gpaReveal,
        builder: (_, __) => const GpaRevealScreen(),
      ),

      // ---- Act 2: account and goal ---------------------------------------
      GoRoute(
        path: Routes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: Routes.profileSetup,
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: Routes.backfill,
        builder: (_, __) => const BackfillScreen(),
      ),
      GoRoute(
        path: Routes.goalSetting,
        builder: (_, __) => const GoalSettingScreen(),
      ),

      // ---- Act 3: the tab shell ------------------------------------------
      // Five tabs, each owning several screens via internal segmented
      // controls. Academics answers "where do I stand", Study answers
      // "what do I do about it".
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, __, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: Routes.academics,
            builder: (_, __) => const AcademicsShell(),
          ),
          GoRoute(
            path: Routes.ai,
            builder: (_, __) => const AiShell(),
          ),
          GoRoute(
            path: Routes.study,
            builder: (_, __) => const StudyShell(),
          ),
          GoRoute(
            path: Routes.me,
            builder: (_, __) => const MeShell(),
          ),
        ],
      ),
    ],

    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Route not found: ${state.uri}'),
        ),
      ),
    ),
  );
});

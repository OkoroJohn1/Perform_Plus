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
import '../../features/home/screens/notifications_panel.dart';
import '../../features/me/screens/me_shell.dart';
import '../../features/onboarding/screens/add_first_results_screen.dart';
import '../../features/onboarding/screens/backfill_screen.dart';
import '../../features/onboarding/screens/goal_setting_screen.dart';
import '../../features/onboarding/screens/gpa_reveal_screen.dart';
import '../../features/onboarding/screens/institution_setup_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/study/screens/study_shell.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Bridges `authStateProvider` changes into go_router's own refresh
/// mechanism. `routerProvider` used to `ref.watch(authStateProvider)`
/// directly, which rebuilt a brand new `GoRouter` — a stateful object that
/// owns the whole navigation stack — on every auth change, including the
/// transient `loading` state set at the start of every sign-in/up attempt.
/// Each new router resets to `initialLocation`, so the sign-in screen was
/// torn down and replaced by a splash-screen flash the instant its button
/// was pressed, on every attempt, success or failure. `refreshListenable`
/// instead tells the SAME long-lived router to just re-run `redirect` for
/// the current location.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,

    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loc = state.matchedLocation;

      // Act 1 is deliberately open. No redirect logic applies here.
      if (Routes.isPreAuth(loc)) return null;

      // authStateProvider is AsyncLoading for at least one microtask on
      // every fresh boot/reload (AsyncNotifier.build() is async, even
      // though it resolves near-instantly here). `auth.valueOrNull` is
      // null during that window — indistinguishable from "signed out" —
      // so treating it as signed-out redirected every non-preauth route to
      // sign-in, and then redirected again once the real value landed a
      // moment later, which showed up as an infinite redirect loop on
      // reload. Never act on an unresolved value: send it to the splash
      // screen instead, which awaits `authStateProvider.future` itself and
      // navigates once auth is actually known. This is reached only for
      // non-preauth locations (the check above already returns null for
      // splash itself), so the redirect is a single, idempotent hop — the
      // very next evaluation sees `loc == Routes.splash`, which is preauth
      // and returns null, not another redirect.
      if (!auth.hasValue) return Routes.splash;

      final signedIn = auth.value!.isSignedIn;
      if (!signedIn) return Routes.signIn;

      // Signed in but profile incomplete — the engine needs entry year and
      // expected graduation year to count remaining semesters. Same rule
      // as above: only act on this once auth has actually resolved, which
      // the guard above already guarantees by this point.
      final profileComplete = auth.value!.profileComplete;
      if (!profileComplete && loc != Routes.profileSetup) {
        return Routes.profileSetup;
      }

      // Profile Setup is only step 2 of Act 2's three screens (Backfill and
      // Goal Setting follow it) -- both of those live under `/onboarding/`
      // and are exempt via `isPreAuth` above, so this only ever fires for
      // an attempt to reach the tab shell. Without this, backgrounding or
      // killing the app between Profile Setup and Goal Setting stranded a
      // student in the tab shell forever on the next launch, since nothing
      // else re-routed them back through Backfill/Goal Setting.
      final onboardingComplete = auth.value!.onboardingComplete;
      if (profileComplete && !onboardingComplete) {
        return Routes.backfill;
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
        path: Routes.institutionSetup,
        builder: (_, __) => const InstitutionSetupScreen(),
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
        builder: (_, state) => ProfileSetupScreen(isEditMode: state.extra == true),
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
          // Reachable from the header bell on every tab except Me. Nested
          // under this same ShellRoute (not a separate top-level route) so
          // AppScaffold — and its bottom nav — stays mounted underneath;
          // see AppScaffold's own doc comment on how it keeps the
          // originating tab highlighted while this route has no tab of
          // its own.
          GoRoute(
            path: Routes.notifications,
            builder: (_, __) => const NotificationsPanel(),
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

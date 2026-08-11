/// Route paths, grouped by act.
///
/// V1 flow: Splash -> Add results -> GPA reveal -> Sign in -> Profile ->
/// Backfill -> Goal setting -> the five tabs. Value (the GPA reveal)
/// arrives before the signup gate — see AGENTS.md's "UX architecture"
/// section for the rationale. There is no institution picker — the app is
/// FUTO-only for now, see AGENTS.md's "Open questions".
class Routes {
  const Routes._();

  // Act 1 — pre-account. Reachable with no session.
  static const splash = '/';
  static const addFirstResults = '/onboarding/results';
  static const gpaReveal = '/onboarding/gpa';

  // Act 2 — account and goal.
  static const signIn = '/auth/sign-in';
  static const profileSetup = '/auth/profile-setup';
  static const backfill = '/onboarding/backfill';
  static const goalSetting = '/onboarding/goal';

  // Act 3 — the five tabs.
  static const home = '/home';
  static const academics = '/academics';
  static const ai = '/ai';
  static const study = '/study';
  static const me = '/me';

  static const _preAuth = <String>{splash, signIn};

  /// Whether a location is reachable without a session — every `/onboarding/`
  /// path is open regardless of act, since the router never gates on
  /// auth there; screens themselves decide what data they need.
  static bool isPreAuth(String location) =>
      _preAuth.contains(location) || location.startsWith('/onboarding/');

  static const tabOrder = <String>[home, academics, ai, study, me];

  static int tabIndexFor(String location) {
    final i = tabOrder.indexWhere((r) => location.startsWith(r));
    return i < 0 ? 0 : i;
  }
}

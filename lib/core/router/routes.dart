/// Route paths, grouped by act.
///
/// V1 flow: Splash -> Institution -> Sign in -> Profile -> Backfill ->
/// Goal setting -> Add results -> GPA reveal -> the five tabs. Auth sits
/// right after institution choice, ahead of every results/goal screen — see
/// AGENTS.md's "UX architecture" section for the rationale.
class Routes {
  const Routes._();

  // Act 1 — pre-account. Reachable with no session.
  static const splash = '/';
  static const institutionSetup = '/onboarding/institution';

  // Act 2 — account, goal and results.
  static const signIn = '/auth/sign-in';
  static const profileSetup = '/auth/profile-setup';
  static const backfill = '/onboarding/backfill';
  static const goalSetting = '/onboarding/goal';
  static const addFirstResults = '/onboarding/results';
  static const gpaReveal = '/onboarding/gpa';

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

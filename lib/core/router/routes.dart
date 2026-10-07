/// Route paths, grouped by act.
///
/// V1 flow: Splash -> Institution -> Add results -> GPA reveal -> Sign in ->
/// Profile -> Backfill -> Goal setting -> the five tabs. Value (the GPA
/// reveal) still arrives before the signup gate — see AGENTS.md's "UX
/// architecture" section for the rationale. The institution picker is back
/// (see AGENTS.md's "Open questions") as the first Act 1 step, ahead of
/// results entry, so the grading scheme is known before any grade is typed.
class Routes {
  const Routes._();

  // Act 1 — pre-account. Reachable with no session.
  static const splash = '/';
  static const institutionSetup = '/onboarding/institution';
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

  /// Pushed from the header bell on Home/Academics/AI/Study — not a tab
  /// itself (Me has no bell). Nested under the same shell as the tabs so
  /// the bottom nav stays visible; see `AppScaffold`.
  static const notifications = '/notifications';

  /// Pushed from the AI tab's "Ask about your results" button and
  /// `AdvisorFab` on Home/Academics/Study — a real screen with its own back
  /// arrow/gesture, not a dismissible sheet (see `advisor_chat_screen.dart`).
  static const advisorChat = '/ai/chat';

  static const _preAuth = <String>{splash, signIn};

  /// Whether a location is reachable without a session — every `/onboarding/`
  /// path is open regardless of act, since the router never gates on
  /// auth there; screens themselves decide what data they need.
  static bool isPreAuth(String location) =>
      _preAuth.contains(location) || location.startsWith('/onboarding/');

  static const tabOrder = <String>[home, academics, ai, study, me];

  /// -1 for a route that isn't one of the five tabs (e.g. [notifications])
  /// — callers that need a tab highlighted regardless (the bottom nav)
  /// decide their own fallback rather than this silently defaulting to
  /// Home, which would be wrong for a route pushed from a different tab.
  static int tabIndexFor(String location) =>
      tabOrder.indexWhere((r) => location.startsWith(r));
}

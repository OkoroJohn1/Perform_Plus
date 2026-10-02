/// App-wide constants.
class AppConstants {
  const AppConstants._();

  static const appName = 'Perform+';
  static const tagline = 'Learn Smarter. Track Better. Graduate Stronger.';

  /// Mirrors pubspec.yaml's `version:` field. Shown on the splash screen.
  static const version = '0.1.0';

  /// Nigerian undergraduate levels.
  static const levels = <int>[100, 200, 300, 400, 500, 600];

  /// Two semesters per level in the standard structure.
  static const semestersPerLevel = 2;

  /// Fallback when a programme's credit load is unknown.
  static const defaultCreditsPerSemester = 20;

  /// Valid credit unit range. Anything outside this is a data-entry error.
  static const minCreditUnit = 1;
  static const maxCreditUnit = 12;

  /// OCR rows below this confidence are flagged for review in the
  /// confirm table rather than silently accepted.
  static const ocrReviewThreshold = 0.85;

  /// Free-tier monthly AI action allowance. "Unlimited" at NGN pricing is
  /// a loss-making promise — see README on unit economics.
  static const freeTierAiActions = 20;
  static const premiumTierAiActions = 200;

  /// The Act 1 steps as a user perceives them — splash isn't one, so this
  /// starts at institution choice. Screens index into this for their step
  /// badge/title/progress-bar fraction (e.g. `institution_setup_screen.dart`
  /// is index 0, "step 1 of `onboardingSteps.length`").
  static const onboardingSteps = <String>[
    'Institution & Scheme Setup',
    'Add Results',
    'Grades',
    'Your GPA',
  ];

  /// Fixed row key for the single local student profile, used by the Drift
  /// layer (`profiles`/`goals` tables) and `Semester.profileId`. Auth is now
  /// real (Supabase), but local storage stays single-profile until the sync
  /// layer maps this row to `AuthState.userId` — every local row belongs to
  /// this one placeholder profile until then.
  static const localProfileId = 'local-profile';

  /// Native Google sign-in (see `auth_provider.dart`) needs an Android
  /// OAuth client (package name + signing-key SHA-1) registered in Google
  /// Cloud Console, plus `GOOGLE_WEB_CLIENT_ID` set in `.env` — neither
  /// exists yet, so the button would fail today even though the flow
  /// itself is implemented. Flip this once both are done — see AGENTS.md's
  /// "Google sign-in setup" for the exact values this project needs.
  /// `sign_in_screen.dart` hides the Google button and its divider on
  /// Android entirely while this is false rather than show a control that
  /// cannot succeed.
  static const enableGoogleSignInOnAndroid = true;

  /// The AI Advisor tab's insight cards are template-generated from
  /// `CgpaEngine`/`ProjectionSolver` output and work today with no backend.
  /// Real conversational chat needs a Supabase Edge Function proxy (API key
  /// server-side, function-calling only, rate-limited) that does not exist
  /// yet — see `advisor_chat_sheet.dart`'s honest "coming soon" stub. Flip
  /// this once that backend ships; the stub UI is built to swap out for the
  /// real chat surface without other changes.
  static const enableAdvisorChat = false;
}

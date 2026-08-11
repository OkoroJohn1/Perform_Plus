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

  /// Fixed row key for the single local student profile, used by the Drift
  /// layer (`profiles`/`goals` tables) and `Semester.profileId`. There is
  /// no real multi-user auth yet — `AuthState.userId` is a separate stub —
  /// so every local row belongs to this one placeholder profile until
  /// Supabase auth lands.
  static const localProfileId = 'local-profile';
}

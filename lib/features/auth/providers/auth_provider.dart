import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, protected;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Prefixed second import of the SAME package, purely to reach gotrue's own
// `AuthState` — our own `AuthState` class below (same name) shadows the
// unprefixed one everywhere in this file, which is fine for every other
// use (`SignOutReason`, `Session`, `AuthException`, ...) but leaves no way
// to name gotrue's type for `authChangeStream()`'s return type without this.
import 'package:supabase_flutter/supabase_flutter.dart' as gotrue;

import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/repository_providers.dart';

/// The Google Cloud "Web application" OAuth client ID — same one used by
/// the web browser-redirect flow below and registered on Supabase's Google
/// provider page. Native sign-in on Android/iOS ALSO needs this passed as
/// `serverClientId`: it's what makes the ID token `google_sign_in` returns
/// carry the audience Supabase expects, regardless of platform. Set in
/// `.env` — never hardcode a real client ID in source.
String? get _googleWebClientId => dotenv.env['GOOGLE_WEB_CLIENT_ID'];

/// A network call to Supabase Auth is given this long before the UI treats
/// it as failed rather than spinning indefinitely — Nigerian mobile data
/// can hang a request well past what feels like a bug to the student.
const authCallTimeout = Duration(seconds: 15);

const _lastAccountEmailKey = 'perform_plus.last_account_email';

/// `local_settings` key set once Goal Setting (the last of Act 2's three
/// screens) is saved or skipped — see [AuthState.onboardingComplete].
const _onboardingCompleteKey = 'onboardingComplete';

/// `local_settings` key holding the profile id (a former real auth uid) of
/// local academic data orphaned by a deleted account — see
/// [AuthNotifier._handleAccountNoLongerExists]. Stored as an empty string,
/// never absent-vs-present, once consumed (offered, attached, or declined)
/// — `LocalSettingsDao` has no delete, and an empty string reads the same
/// as "nothing to offer".
const _orphanedLocalDataUidKey = 'perform_plus.orphaned_local_data_uid';

/// Auth state.
class AuthState {
  final String? userId;
  final String? email;
  final bool profileComplete;

  /// The sign-in method behind the current session (`'google'`, `'email'`,
  /// ...) — Supabase's `app_metadata.provider`. Used only to hide the
  /// settings screen's "Change password" row for a Google-only account,
  /// which has no password to change.
  final String? provider;

  /// Whether the student has finished the WHOLE Act 2 sequence (Profile
  /// Setup -> Backfill -> Goal Setting), not just Profile Setup.
  /// [profileComplete] only tracks the first of those three screens; without
  /// this separate, persisted flag, backgrounding/killing the app between
  /// Profile Setup and Goal Setting stranded a student permanently, because
  /// `splash_screen.dart` sends any signed-in user straight to the tab
  /// shell and the router's `redirect` had nothing else to check.
  final bool onboardingComplete;

  const AuthState({
    this.userId,
    this.email,
    this.profileComplete = false,
    this.provider,
    this.onboardingComplete = false,
  });

  bool get isSignedIn => userId != null;
  bool get isGoogleOnly => provider == 'google';

  static const signedOut = AuthState();
}

/// A client-composed auth message that didn't come from a Supabase
/// [AuthException] — e.g. "check your email to confirm". Handled the same
/// as any other auth failure by [authErrorMessage].
class AuthFlowException implements Exception {
  final String message;
  const AuthFlowException(this.message);
}

/// Maps an error thrown by [AuthNotifier] to copy a form can show directly.
/// Never surface a raw Supabase error string — a student has no way to act
/// on "AuthApiException: invalid_grant".
String authErrorMessage(Object error) {
  if (error is AuthFlowException) return error.message;

  if (error is TimeoutException || error is AuthRetryableFetchException) {
    return "Can't reach the server. Check your connection and try again.";
  }

  if (error is AuthWeakPasswordException) {
    return 'Password needs at least 8 characters.';
  }

  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return "That email and password don't match. Check both, or "
            'create an account below.';
      case 'user_already_exists':
      case 'email_exists':
        return 'You already have an account. Sign in instead.';
      case 'weak_password':
        return 'Password needs at least 8 characters.';
      case 'email_not_confirmed':
        return 'Confirm your email address before signing in — check your '
            'inbox.';
      case 'over_email_send_rate_limit':
        return 'Too many attempts. Wait a moment and try again.';
    }
    return error.message;
  }

  return 'Something went wrong. Please try again.';
}

/// Whether an error represents an existing account colliding with a sign-up
/// attempt — `sign_in_screen.dart` offers an inline "Sign in instead" action
/// only for this case, since it's the one error a plain retry can't fix.
bool isAccountAlreadyExistsError(Object error) =>
    error is AuthException &&
    (error.code == 'user_already_exists' || error.code == 'email_exists');

/// Backed by Supabase auth (email/password, Google OAuth). Session restore
/// on launch reads whatever `supabase_flutter` already persisted locally —
/// see [build].
class AuthNotifier extends AsyncNotifier<AuthState> {
  SupabaseClient get _client => ref.read(supabaseClientProvider);

  /// The stream of auth-change events [build] reacts to. Real
  /// implementation just reads the live Supabase client; overridden by
  /// `auth_provider_test.dart` to drive specific events (an invalid-
  /// refresh-token `signedOut`, in particular) deterministically, without
  /// constructing a real `SupabaseClient`/`GoTrueClient` — heavyweight and,
  /// for a rejected-refresh-token event specifically, not something a test
  /// can trigger on demand from a real client anyway.
  @protected
  Stream<gotrue.AuthState> authChangeStream() => _client.auth.onAuthStateChange;

  /// The cached user [build] resolves its initial state from. Same
  /// test-seam reasoning as [authChangeStream] — overridden to `null` so a
  /// test starts clean and drives every subsequent state purely through
  /// the injected stream.
  @protected
  User? currentUserSeam() => _client.auth.currentUser;

  @override
  Future<AuthState> build() async {
    // Google's OAuth redirect lands well after signInWithGoogle() has
    // already returned (its return value only confirms the browser/tab was
    // launched, not that sign-in completed — see that method). This is the
    // listener that actually applies the resulting session once the
    // redirect lands. It also fires for email sign-in/up's own session
    // changes, redundantly with the explicit handling in those methods —
    // harmless, since applying the same session twice is idempotent.
    final subscription = authChangeStream().listen((data) {
      final session = data.session;
      if (session == null) {
        // A genuine sign-out (or an unrecoverable session, e.g. an
        // irrevocably invalid refresh token) -- previously silently
        // ignored here, which left this provider's state stuck on
        // whatever it last resolved to even though the SDK itself no
        // longer considers the student signed in. Reflect it immediately
        // rather than only finding out on the next full app restart.
        //
        // `signOutReason` tells an explicit `signOut()` call apart from an
        // involuntary one. `sessionExpired` is what a rejected refresh
        // token surfaces as -- both a genuinely expired token AND the
        // account it belonged to having been deleted server-side (Supabase
        // doesn't push a "your account was deleted" event; the deletion is
        // only ever discovered the next time a refresh or an authenticated
        // call fails to resolve the user, e.g. `user_not_found`). Route
        // that specific case through its own handler rather than the plain
        // sign-out path below.
        if (data.signOutReason == SignOutReason.sessionExpired) {
          unawaited(_handleAccountNoLongerExists());
          return;
        }
        state = const AsyncValue.data(AuthState.signedOut);
        return;
      }
      unawaited(_applySessionChange(session));
    });
    ref.onDispose(subscription.cancel);

    final user = currentUserSeam();
    if (user == null) return AuthState.signedOut;
    return _stateFor(user);
  }

  Future<void> _applySessionChange(Session session) async {
    state = await AsyncValue.guard(() => _stateFor(session.user));
  }

  /// The account behind the current session no longer exists server-side.
  /// Local data is deliberately left completely alone here -- a student's
  /// results are theirs, and on this device may be all that is left of
  /// that account. All this does is: make sure no stale session survives
  /// locally, remember where any local academic data is so a future
  /// sign-up can offer to reclaim it, and stop nudging the student toward
  /// a "Welcome back" sign-in for an account that can never sign in again.
  Future<void> _handleAccountNoLongerExists() async {
    final outgoingUid = state.valueOrNull?.userId;

    // The SDK already called its own internal `_removeSession()` before
    // this event fired, so there's no access token left to send and this
    // never reaches the network -- a defensive, explicit local clear
    // rather than trusting that internal call alone.
    try {
      await _client.auth.signOut();
    } catch (_) {}

    if (outgoingUid != null) {
      final hasLocalData = await ref
          .read(academicRecordRepositoryProvider)
          .hasSemestersForProfile(outgoingUid);
      if (hasLocalData) {
        await ref
            .read(localSettingsDaoProvider)
            .set(_orphanedLocalDataUidKey, outgoingUid);
      }
    }

    // A remembered email now points at an account that can never sign in
    // again -- clear it so the sign-in screen defaults to sign-up mode,
    // matching the "sign up to save them again" message rather than
    // contradicting it with a "Welcome back" form pre-filled for a dead
    // account.
    try {
      await ref.read(secureStorageProvider).delete(key: _lastAccountEmailKey);
    } catch (_) {}

    state = const AsyncValue.data(AuthState.signedOut);
    ref.read(accountDeletedProvider.notifier).state = true;
  }

  /// Checked once, right after a successful sign-up -- if
  /// [_handleAccountNoLongerExists] previously stashed an orphaned profile
  /// id (and this isn't somehow that same account again), surfaces it via
  /// [pendingLocalDataAttachProvider] for the profile-setup screen to offer
  /// reattaching. Never fires on sign-in: attaching a stranger's leftover
  /// data to an already-established different account is not the same
  /// obviously-safe default as a brand-new, empty one.
  ///
  /// Not private (though only ever called internally by [signUpWithEmail])
  /// so `auth_provider_test.dart` can drive it directly -- the real
  /// trigger is a live `_client.auth.signUp` call, which has no test seam
  /// of its own and isn't what this behaviour is actually about.
  @protected
  Future<void> checkForOrphanedLocalData(String newUid) async {
    final dao = ref.read(localSettingsDaoProvider);
    final orphanedUid = await dao.get(_orphanedLocalDataUidKey);
    if (orphanedUid == null || orphanedUid.isEmpty || orphanedUid == newUid) {
      return;
    }
    final stillHasData = await ref
        .read(academicRecordRepositoryProvider)
        .hasSemestersForProfile(orphanedUid);
    if (!stillHasData) {
      await dao.set(_orphanedLocalDataUidKey, '');
      return;
    }
    ref.read(pendingLocalDataAttachProvider.notifier).state = orphanedUid;
  }

  /// Confirmed by the student on the offer surfaced via
  /// [pendingLocalDataAttachProvider] -- moves the orphaned account's
  /// semesters onto the new one, via the same [reassignProfile] mechanism
  /// already used for the pre-auth draft handoff, just with a different
  /// source id.
  Future<void> attachOrphanedLocalData() async {
    final orphanedUid = ref.read(pendingLocalDataAttachProvider);
    final newUid = state.valueOrNull?.userId;
    if (orphanedUid == null || newUid == null) return;
    await ref
        .read(academicRecordRepositoryProvider)
        .reassignProfile(orphanedUid, newUid);
    await ref.read(localSettingsDaoProvider).set(_orphanedLocalDataUidKey, '');
    ref.read(pendingLocalDataAttachProvider.notifier).state = null;
  }

  /// Declined -- the offer is made once, per its own requirement; never
  /// asked again for this same orphaned data.
  void dismissOrphanedLocalDataOffer() {
    unawaited(
      ref.read(localSettingsDaoProvider).set(_orphanedLocalDataUidKey, ''),
    );
    ref.read(pendingLocalDataAttachProvider.notifier).state = null;
  }

  /// `profileComplete` is answered from the *local* Drift profile, not a
  /// remote fetch — the sync layer doesn't exist yet, and local Drift is the
  /// source of truth per the local-first architecture.
  ///
  /// Also the single funnel every successful auth resolution passes through
  /// (sign in, sign up, Google, and session restore on launch), so it's
  /// where two handoff steps live rather than being duplicated per method:
  ///   1. Remember this email locally (not the session — `supabase_flutter`
  ///      already persists that) so a returning user defaults to sign-in
  ///      mode with the field pre-filled next time.
  ///   2. Hand off any pre-auth draft semester from the placeholder profile
  ///      id to this real uid -- UNLESS this uid already has real semesters
  ///      on this device, in which case the draft is discarded instead.
  ///      That case is not a legitimate second batch of results: it means
  ///      this device lost track of an already-signed-in session (e.g. a
  ///      session-restore race on a cold app start) and the student was
  ///      routed back through onboarding and re-entered results that
  ///      already exist under their real account. Blindly reassigning would
  ///      silently duplicate every semester instead of just dropping the
  ///      stray re-entry.
  Future<AuthState> _stateFor(User user) async {
    if (user.email != null) {
      unawaited(_rememberAccountEmail(user.email!));
    }
    final academicRecordRepository = ref.read(academicRecordRepositoryProvider);
    final alreadyHasRecords =
        await academicRecordRepository.hasSemestersForProfile(user.id);
    if (alreadyHasRecords) {
      await academicRecordRepository.discardProfile(AppConstants.localProfileId);
    } else {
      await academicRecordRepository.reassignProfile(AppConstants.localProfileId, user.id);
    }
    final profile = await ref.read(profileRepositoryProvider).loadProfile();
    final onboardingComplete =
        await ref.read(localSettingsDaoProvider).get(_onboardingCompleteKey) == 'true';
    return AuthState(
      userId: user.id,
      email: user.email,
      profileComplete: profile != null,
      provider: user.appMetadata['provider'] as String?,
      onboardingComplete: onboardingComplete,
    );
  }

  Future<void> _rememberAccountEmail(String email) async {
    try {
      await ref
          .read(secureStorageProvider)
          .write(key: _lastAccountEmailKey, value: email);
    } catch (_) {
      // Purely a convenience default for next time — never block or fail
      // auth over a secure-storage write error.
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(authCallTimeout);
      final user = response.user;
      if (user == null) {
        throw const AuthFlowException('Sign in failed. Please try again.');
      }
      return _stateFor(user);
    });
  }

  /// The `profiles` row for a new user is created by a database trigger on
  /// `auth.users` insert (see the provisioned schema) — never insert one
  /// from the client here. Once the sync layer exists, it should fetch that
  /// trigger-created row and update it, never insert.
  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _client.auth
          .signUp(email: email, password: password)
          .timeout(authCallTimeout);
      final user = response.user;
      if (user == null) {
        throw const AuthFlowException(
          'Could not create account. Please try again.',
        );
      }
      // Supabase returns a 200 with an empty `identities` list rather than
      // throwing when the email is already registered and confirmed — its
      // anti-enumeration behaviour. Without this check it would silently
      // fall through as if a new account had been created.
      if (user.identities?.isEmpty ?? false) {
        throw const AuthException(
          'You already have an account. Sign in instead.',
          code: 'user_already_exists',
        );
      }
      // Email confirmation is required by the project and no session was
      // issued yet — nothing to sign the user into until they confirm.
      if (response.session == null) {
        throw const AuthFlowException(
          'Account created. Check your email to confirm your address, then '
          'sign in.',
        );
      }
      return _stateFor(user);
    });

    final signedInUid = state.valueOrNull?.userId;
    if (signedInUid != null) {
      unawaited(checkForOrphanedLocalData(signedInUid));
    }
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email).timeout(authCallTimeout);
  }

  /// PIN-recovery last resort, reached only once both the PIN pad
  /// ([pinMaxAttempts] wrong guesses) and security questions have failed
  /// a student. Sends a 6-digit code to the ALREADY-registered account
  /// email (`shouldCreateUser: false` -- this must never silently create a
  /// new account for a typo'd address) rather than a clickable link, so
  /// the whole recovery stays inside the app instead of handing off to a
  /// browser/mail client and back.
  Future<void> sendPinResetCode(String email) async {
    await _client.auth
        .signInWithOtp(email: email, shouldCreateUser: false)
        .timeout(authCallTimeout);
  }

  /// Verifies the code from [sendPinResetCode]. Success proves the student
  /// currently controls the registered email, independent of whatever
  /// local session already existed -- the caller (the PIN-recovery screen)
  /// treats that as sufficient to clear the local PIN and let a new one be
  /// set.
  Future<void> verifyPinResetCode(String email, String code) async {
    await _client.auth
        .verifyOTP(email: email, token: code, type: OtpType.email)
        .timeout(authCallTimeout);
  }

  /// The settings screen's "Change password" row -- needs the network
  /// (Supabase must issue a new session), so a caller should show a clear
  /// offline message rather than let this hang. Not exposed for a
  /// Google-only account (see [AuthState.isGoogleOnly]) since there is no
  /// password to change.
  Future<void> changePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword)).timeout(authCallTimeout);
  }

  /// Same profile handling as email auth: the `profiles` row is created by
  /// the database trigger on first sign-in, never inserted from here.
  ///
  /// Web keeps the browser-redirect OAuth flow — it already works, and
  /// `google_sign_in`'s web integration has its own separate rendering
  /// requirements that don't fit this screen's custom button. Android/iOS
  /// use the native account picker instead: no browser page, so Google's
  /// "unverified app" security-challenge screen (the one that shows a
  /// "get a code to sign in, go to g.co/sc" prompt) never has a browser
  /// context to appear in. Native sign-in needs its own Google Cloud OAuth
  /// client per platform (Android: package name + signing-key SHA-1; iOS:
  /// bundle id) registered in Google Cloud Console and added to Supabase's
  /// Google provider — see AGENTS.md for this project's exact values.
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      try {
        final launched = await _client.auth.signInWithOAuth(OAuthProvider.google);
        if (!launched) {
          throw const AuthFlowException(
            'Could not open Google sign-in. Please try again.',
          );
        }
        // Nothing more to do here on success — signInWithOAuth only
        // confirms the browser tab was launched, not that sign-in
        // completed. The onAuthStateChange listener in build() applies the
        // resulting session once the redirect actually lands. If the user
        // closes the tab without finishing, nothing fires and the app is
        // simply left as it was — never stuck "loading". (The button's own
        // loading indicator is local to `sign_in_screen.dart`, scoped to
        // just this launch attempt, for exactly that reason — this branch
        // never touches `state`.)
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final googleUser =
          await GoogleSignIn(serverClientId: _googleWebClientId).signIn();
      if (googleUser == null) {
        // User dismissed the native picker — not an error. This method
        // only ever runs from the sign-in screen while signed out, so
        // that's the correct state to settle back on.
        return AuthState.signedOut;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw const AuthFlowException(
          'Could not sign in with Google. Please try again.',
        );
      }

      await _client.auth
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: googleAuth.accessToken,
          )
          .timeout(authCallTimeout);

      final user = _client.auth.currentUser;
      if (user == null) {
        throw const AuthFlowException(
          'Could not sign in with Google. Please try again.',
        );
      }
      return _stateFor(user);
    });
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Best-effort — the user must never be stuck "signed in" locally just
      // because the network call to invalidate the remote session failed.
    }
    state = const AsyncValue.data(AuthState.signedOut);
    ref.read(justSignedOutProvider.notifier).state = true;
  }

  /// Clears a form-level error left over from a previous attempt — e.g.
  /// `sign_in_screen.dart` switching sign-up/sign-in mode. A no-op unless
  /// `state` is actually an error, since this screen only renders while
  /// signed out and must never overwrite a genuine signed-in state.
  void clearError() {
    if (state.hasError) state = const AsyncValue.data(AuthState.signedOut);
  }

  /// Called once the profile-setup form is saved. TODO(v1): persist
  /// alongside the Supabase profile row once the sync layer exists.
  void markProfileComplete() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      AuthState(
        userId: current.userId,
        email: current.email,
        profileComplete: true,
        provider: current.provider,
        onboardingComplete: current.onboardingComplete,
      ),
    );
  }

  /// Called once Goal Setting is saved or skipped — the last of Act 2's
  /// three screens. Persisted (not just in-memory) so the router's
  /// `redirect` can tell "finished onboarding" apart from "just backgrounded
  /// mid-flow" on the next cold start — see [AuthState.onboardingComplete].
  Future<void> markOnboardingComplete() async {
    await ref.read(localSettingsDaoProvider).set(_onboardingCompleteKey, 'true');
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      AuthState(
        userId: current.userId,
        email: current.email,
        profileComplete: current.profileComplete,
        provider: current.provider,
        onboardingComplete: true,
      ),
    );
  }
}

final supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

final secureStorageProvider =
    Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

/// The last email this device signed in/up with, if any — `null` means no
/// prior account, which is `sign_in_screen.dart`'s cue to default to sign-up
/// mode rather than the "Welcome back" framing.
final lastAccountEmailProvider = FutureProvider<String?>((ref) async {
  try {
    return await ref
        .read(secureStorageProvider)
        .read(key: _lastAccountEmailKey);
  } catch (_) {
    // No prior-account signal beats a broken one — fall back to sign-up.
    return null;
  }
});

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Flips true for one frame right after [AuthNotifier.signOut] so the sign-in
/// screen can show a one-line "you've been logged out" confirmation without
/// a dedicated route. The sign-in screen resets it after showing the message.
final justSignedOutProvider = StateProvider<bool>((ref) => false);

/// Flips true when [AuthNotifier] detects the signed-in account no longer
/// exists server-side (see `AuthNotifier._handleAccountNoLongerExists`) --
/// distinct from [justSignedOutProvider], an explicit, expected sign-out.
/// The sign-in screen reads the CURRENT value once (in `initState`, not via
/// `ref.listen`, which only fires on a change after it starts listening and
/// would miss a value already flipped before this screen ever mounts) to
/// show a message explaining why the student landed back here uninvited,
/// then resets it.
final accountDeletedProvider = StateProvider<bool>((ref) => false);

/// Set to the profile id (a former real auth uid) of local academic data
/// left behind by a deleted account once there is something to offer
/// re-attaching to a freshly created account — `null` otherwise. Read the
/// same read-once way as [accountDeletedProvider], by whichever screen a
/// fresh sign-up always lands on.
final pendingLocalDataAttachProvider = StateProvider<String?>((ref) => null);

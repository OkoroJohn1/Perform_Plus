import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auth state.
class AuthState {
  final String? userId;
  final String? email;
  final bool profileComplete;

  const AuthState({this.userId, this.email, this.profileComplete = false});

  bool get isSignedIn => userId != null;

  static const signedOut = AuthState();
}

/// TODO(v1): back this with Supabase auth.
///
/// SECURITY: never ship API keys in the Flutter binary — it decompiles
/// trivially. All AI calls proxy through your backend, which is also where
/// per-user rate limiting is enforced.
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async => AuthState.signedOut;

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    // TODO(v1): supabase.auth.signInWithPassword(...)
    state = AsyncValue.data(
      AuthState(userId: 'local-dev', email: email, profileComplete: false),
    );
  }

  Future<void> signInWithGoogle() async {
    // TODO(v1): supabase.auth.signInWithOAuth(Provider.google)
  }

  Future<void> signOut() async {
    state = const AsyncValue.data(AuthState.signedOut);
    ref.read(justSignedOutProvider.notifier).state = true;
  }

  /// Called once the profile-setup form is saved. TODO(v1): persist
  /// alongside the Supabase profile row once auth is real.
  void markProfileComplete() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      AuthState(
        userId: current.userId,
        email: current.email,
        profileComplete: true,
      ),
    );
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Flips true for one frame right after [AuthNotifier.signOut] so the sign-in
/// screen can show a one-line "you've been logged out" confirmation without
/// a dedicated route. The sign-in screen resets it after showing the message.
final justSignedOutProvider = StateProvider<bool>((ref) => false);

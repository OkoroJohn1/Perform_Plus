import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/features/auth/providers/auth_provider.dart';
import 'package:perform_plus/features/auth/screens/sign_in_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

/// `authStateProvider`'s real implementation touches `Supabase.instance`,
/// never initialized in a plain `flutter test` run — stand in with a fixed
/// signed-out state, same reason `dashboard_screen_test.dart` does this.
class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => AuthState.signedOut;
}

/// Simulates a real "wrong password" rejection from Supabase without ever
/// touching the network.
class _FailingSignInAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => AuthState.signedOut;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    state = const AsyncValue.error(
      AuthException('Invalid login credentials', code: 'invalid_credentials'),
      StackTrace.empty,
    );
  }
}

Widget _app({
  required String? lastEmail,
  AuthNotifier Function() authNotifier = _FakeAuthNotifier.new,
}) =>
    ProviderScope(
      overrides: [
        lastAccountEmailProvider.overrideWith((ref) async => lastEmail),
        authStateProvider.overrideWith(authNotifier),
      ],
      child: const MaterialApp(home: SignInScreen()),
    );

GestureDetector _primaryButton(WidgetTester tester) => tester.widget(
      find.byKey(const ValueKey('primaryAuthButtonTap')),
    );

void main() {
  testWidgets('defaults to sign-up mode when no prior account exists',
      (tester) async {
    await tester.pumpWidget(_app(lastEmail: null));
    await tester.pumpAndSettle();

    expect(find.text('Save your result'), findsOneWidget);
    expect(find.text('Welcome back 👋'), findsNothing);
  });

  testWidgets('primary button is disabled until the form is valid',
      (tester) async {
    await tester.pumpWidget(_app(lastEmail: null));
    await tester.pumpAndSettle();

    expect(_primaryButton(tester).onTap, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('emailField')),
      'ada@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('passwordField')),
      'password123',
    );
    await tester.pump();

    // Sign-up mode also needs a matching confirm-password field.
    expect(_primaryButton(tester).onTap, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('confirmPasswordField')),
      'password123',
    );
    await tester.pump();

    expect(_primaryButton(tester).onTap, isNotNull);
  });

  testWidgets(
      'a failed sign-in leaves the user on this screen with the error visible',
      (tester) async {
    await tester.pumpWidget(
      _app(lastEmail: 'ada@example.com', authNotifier: _FailingSignInAuthNotifier.new),
    );
    await tester.pumpAndSettle();

    // A remembered email defaults this screen to sign-in mode.
    expect(find.text('Welcome back 👋'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('passwordField')),
      'wrong-password',
    );
    await tester.pump();

    // Tapping this would throw if the screen tried `context.go` without a
    // GoRouter ancestor — which it must never do on a failed attempt.
    await tester.tap(find.byKey(const ValueKey('primaryAuthButtonTap')));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.textContaining("don't match"), findsOneWidget);
  });
}

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/features/auth/providers/auth_provider.dart';
import 'package:perform_plus/features/auth/screens/profile_setup_screen.dart';
import 'package:perform_plus/features/onboarding/providers/onboarding_provider.dart';

/// `authStateProvider`'s real implementation touches `Supabase.instance`,
/// never initialized in a plain `flutter test` run.
class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => AuthState.signedOut;
}

Widget _app() => ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(
          AppDatabase.forTesting(NativeDatabase.memory()),
        ),
        authStateProvider.overrideWith(_FakeAuthNotifier.new),
        // UNN has no catalogued faculty/department list, so Faculty is
        // optional free text and Department a plain autocomplete field —
        // this keeps the test to one dropdown interaction (Entry Year)
        // instead of chasing faculty-filtered department options.
        onboardingDraftProvider.overrideWith(
          (ref) => OnboardingDraftNotifier()..setInstitution('unn'),
        ),
      ],
      child: const MaterialApp(home: ProfileSetupScreen()),
    );

GestureDetector _continueButton(WidgetTester tester) => tester.widget(
      find.byKey(const ValueKey('profileContinueButtonTap')),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('Continue is disabled until the required fields are valid',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(_continueButton(tester).onTap, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('fullNameField')),
      'Ada Obi',
    );
    // Deliberately a number whose leading digits derive an out-of-range
    // year (1999), so the entry-year prefill is rejected and the dropdown
    // below is what actually has to enable Continue.
    await tester.enterText(
      find.byKey(const ValueKey('regNumberField')),
      '99999999',
    );
    await tester.enterText(
      find.byKey(const ValueKey('departmentField')),
      'Computer Science',
    );
    await tester.pump();

    // Current Level already has a default; entry/grad year do not.
    expect(_continueButton(tester).onTap, isNull);

    final entryYearDropdown = find.descendant(
      of: find.byKey(const ValueKey('entryYearField')),
      matching: find.byType(DropdownButtonFormField<int>),
    );
    await tester.ensureVisible(entryYearDropdown);
    await tester.pumpAndSettle();
    await tester.tap(entryYearDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2021').last);
    await tester.pumpAndSettle();

    // Expected graduation defaults automatically once entry year is set.
    expect(_continueButton(tester).onTap, isNotNull);
  });
}

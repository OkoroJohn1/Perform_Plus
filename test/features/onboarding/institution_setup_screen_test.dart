import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/features/onboarding/screens/institution_setup_screen.dart';

Widget _app() => ProviderScope(
      overrides: [
        // The real constructor hits path_provider platform channels, which
        // throw/hang in a plain `flutter test` run — see
        // repository_providers.dart's doc comment.
        appDatabaseProvider.overrideWithValue(
          AppDatabase.forTesting(NativeDatabase.memory()),
        ),
      ],
      child: const MaterialApp(home: InstitutionSetupScreen()),
    );

GestureDetector _continueButton(WidgetTester tester) => tester.widget(
      find.byKey(const ValueKey('continueButtonTap')),
    );

void main() {
  // Each test constructs its own in-memory AppDatabase — intentional
  // isolation, not the accidental-duplicate case this heuristic warns about.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('FUTO is shown centered with no other institution offered',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      find.text('Federal University of Technology, Owerri'),
      findsOneWidget,
    );
    expect(find.text('FUTO'), findsOneWidget);
    // Single-institution mode: no search field, no other school, no
    // manual-entry escape hatch.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('University of Nigeria, Nsukka'), findsNothing);
    expect(find.text('Other (Add Manually)'), findsNothing);
  });

  testWidgets('Continue is enabled immediately -- FUTO is auto-selected',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(_continueButton(tester).onTap, isNotNull);
  });

  testWidgets(
      'auto-selecting FUTO persists its verified scheme as the active one',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: InstitutionSetupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // FUTO's scheme is the one verified entry -- no warning banner.
    expect(find.textContaining("haven't confirmed"), findsNothing);
    expect(
      find.text('Use default scheme for Federal University of Technology, Owerri'),
      findsOneWidget,
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(InstitutionSetupScreen)),
    );
    final scheme = await container.read(gradingSchemeRepositoryProvider).loadActiveScheme();
    expect(scheme?.institutionId, 'futo');
    expect(scheme?.isVerified, isTrue);
  });
}

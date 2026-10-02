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

  testWidgets('search filters the list by abbreviation', (tester) async {
    await tester.pumpWidget(_app());

    await tester.enterText(find.byType(TextField), 'unn');
    await tester.pump();

    expect(find.text('University of Nigeria, Nsukka'), findsOneWidget);
    expect(
      find.text('Federal University of Technology, Owerri'),
      findsNothing,
    );
    // The pinned "Other" row survives every filter.
    expect(find.text('Other (Add Manually)'), findsOneWidget);
  });

  testWidgets('Continue is disabled until an institution is selected',
      (tester) async {
    await tester.pumpWidget(_app());

    expect(_continueButton(tester).onTap, isNull);

    await tester.tap(find.text('Federal University of Technology, Owerri'));
    await tester.pumpAndSettle();

    expect(_continueButton(tester).onTap, isNotNull);
  });

  testWidgets('selecting an unverified scheme surfaces the warning',
      (tester) async {
    // The default 800x600 test surface is short enough that, with the
    // footer's added "Already have an account?" link claiming more fixed
    // height, the second search result can sit outside the list sliver's
    // near-viewport build range. A taller surface sidesteps that instead
    // of fighting scroll precision in the test (same pattern used for the
    // Me tab's grading-scheme sheet, another screen taller than the
    // default viewport).
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());

    // FUTO's scheme is the one verified entry — no warning expected for it.
    await tester.tap(find.text('Federal University of Technology, Owerri'));
    await tester.pumpAndSettle();
    expect(find.textContaining("haven't confirmed"), findsNothing);

    // UNN's is a seeded default, not registry-confirmed — must warn.
    await tester.tap(find.text('University of Nigeria, Nsukka'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "We haven't confirmed UNN's exact grading rules yet. Check the "
        'defaults before you rely on your CGPA.',
      ),
      findsOneWidget,
    );
  });
}

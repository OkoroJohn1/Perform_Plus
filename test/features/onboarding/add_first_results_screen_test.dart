import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/features/onboarding/screens/add_first_results_screen.dart';

Widget _app({
  PickImage? debugPickImage,
  CheckOnline? debugCheckOnline,
}) =>
    ProviderScope(
      child: MaterialApp(
        home: AddFirstResultsScreen(
          debugPickImage: debugPickImage,
          debugCheckOnline: debugCheckOnline,
        ),
      ),
    );

GestureDetector _continueButton(WidgetTester tester) => tester.widget(
      find.byKey(const ValueKey('continueButtonTap')),
    );

void main() {
  testWidgets('Continue is disabled until a photo or a manual row exists',
      (tester) async {
    await tester.pumpWidget(_app());

    expect(_continueButton(tester).onTap, isNull);

    final manualButton = find.text('Enter results manually');
    await tester.ensureVisible(manualButton);
    await tester.pumpAndSettle();
    await tester.tap(manualButton);
    await tester.pump();

    // A blank row exists but has no course code/credit unit yet.
    expect(_continueButton(tester).onTap, isNull);

    final courseField = find.widgetWithText(TextFormField, 'Course');
    await tester.ensureVisible(courseField);
    await tester.enterText(courseField, 'CSC101');
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();

    expect(_continueButton(tester).onTap, isNotNull);
  });

  testWidgets('term label reads from the active scheme, not hardcoded',
      (tester) async {
    await tester.pumpWidget(_app());

    // The draft defaults to FUTO, whose scheme names terms Harmattan/Rain —
    // never the generic "First Semester" this screen used to hardcode.
    expect(find.text('Harmattan Semester'), findsOneWidget);
    expect(find.text('First Semester'), findsNothing);
  });

  testWidgets('a denied picker falls through to manual entry, never a dead end',
      (tester) async {
    await tester.pumpWidget(
      _app(debugPickImage: (source) async => throw Exception('denied')),
    );

    await tester.tap(find.text('Upload or take a photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("Couldn't access your camera or photos"),
      findsOneWidget,
    );
    // Manual course entry is now reachable without any further taps.
    expect(find.widgetWithText(TextFormField, 'Course'), findsOneWidget);
    expect(find.text('Add another course'), findsOneWidget);
  });
}

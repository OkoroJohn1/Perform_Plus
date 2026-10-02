import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/repositories/academic_record_provider.dart';
import 'package:perform_plus/data/seed/nigerian_institutions.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/features/onboarding/providers/onboarding_provider.dart';
import 'package:perform_plus/features/onboarding/screens/gpa_reveal_screen.dart';

/// Subclasses [OnboardingDraftNotifier] purely to seed its state directly —
/// there is no `.seeded()` factory on it (unlike `AcademicRecordController`)
/// because production code never needs one; tests do.
class _SeededDraftNotifier extends OnboardingDraftNotifier {
  _SeededDraftNotifier(OnboardingDraft draft) {
    state = draft;
  }
}

Semester _semesterWith(List<CourseResult> results) {
  final now = DateTime.now();
  return Semester(
    id: 'sem-1',
    profileId: 'p1',
    session: '2023/2024',
    term: SemesterTerm.first,
    level: 100,
    results: results,
    createdAt: now,
    updatedAt: now,
  );
}

CourseResult _result(String code, int units, String grade) {
  final now = DateTime.now();
  return CourseResult(
    id: code,
    semesterId: 'sem-1',
    courseCode: code,
    creditUnit: units,
    grade: grade,
    createdAt: now,
    updatedAt: now,
  );
}

Future<Widget> _app(List<CourseResult> results) async {
  final scheme = defaultSchemes['futo']!;
  final draft = OnboardingDraft(
    institutionId: 'futo',
    scheme: scheme,
    session: '2023/2024',
    level: 100,
    term: SemesterTerm.first,
    rows: const [],
    committed: _semesterWith(results),
  );

  return ProviderScope(
    overrides: [
      onboardingDraftProvider.overrideWith((ref) => _SeededDraftNotifier(draft)),
      academicRecordProvider.overrideWith(
        (ref) => AcademicRecordController.seeded(
          AcademicRecord(semesters: const [], scheme: scheme),
        ),
      ),
    ],
    child: const MaterialApp(home: GpaRevealScreen()),
  );
}

void main() {
  testWidgets(
      'classification pill reads the band from the scheme, not a hardcoded label',
      (tester) async {
    // 5 units at C (3.0) => gpa 3.00, which under FUTO's standard bands
    // falls in Second Class Honours (Lower Division), shortLabel "2:2".
    await tester.pumpWidget(await _app([_result('CSC201', 5, 'C')]));
    await tester.pumpAndSettle();

    expect(find.text('2:2'), findsOneWidget);
    expect(find.text('Excellent'), findsNothing);
  });

  testWidgets('confetti is suppressed for a lower classification band',
      (tester) async {
    // Same 2:2 result as above — not one of the top two bands.
    await tester.pumpWidget(await _app([_result('CSC201', 5, 'C')]));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('gpaRevealConfetti')), findsNothing);
  });

  testWidgets('confetti plays for a top-two classification band',
      (tester) async {
    // 5 units at A (5.0) => gpa 5.00 => First Class, the top band.
    await tester.pumpWidget(await _app([_result('CSC201', 5, 'A')]));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('gpaRevealConfetti')), findsOneWidget);
  });

  testWidgets('an excluded result surfaces its reason and a way to fix it',
      (tester) async {
    // "Z" is not a letter FUTO's scheme defines, so it is excluded rather
    // than silently zeroed.
    await tester.pumpWidget(await _app([
      _result('CSC201', 5, 'B'),
      _result('MTH205', 3, 'Z'),
    ]));
    await tester.pumpAndSettle();

    expect(find.textContaining('MTH205'), findsOneWidget);
    expect(find.textContaining('Unrecognised grade'), findsOneWidget);
    expect(find.text('Fix'), findsOneWidget);
  });

  testWidgets(
      'the calculation breakdown sums to exactly the displayed GPA',
      (tester) async {
    // CSC201: 3 units x B(4.0) = 12; MTH101: 2 units x C(3.0) = 6.
    // Total 18 / 5 units = 3.60.
    await tester.pumpWidget(await _app([
      _result('CSC201', 3, 'B'),
      _result('MTH101', 2, 'C'),
    ]));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('How this was calculated'));
    await tester.tap(find.text('How this was calculated'));
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('18 ÷ 5'), findsOneWidget);
    // Appears once in the gauge and once in the total row.
    expect(find.text('3.60'), findsNWidgets(2));
  });
}

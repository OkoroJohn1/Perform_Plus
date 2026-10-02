import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/academic_record_provider.dart';
import 'package:perform_plus/data/repositories/drift_profile_repository.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/data/seed/nigerian_institutions.dart';
import 'package:perform_plus/domain/engine/cgpa_engine.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/domain/models/student_profile.dart';
import 'package:perform_plus/features/onboarding/screens/goal_setting_screen.dart';

/// Two semesters (so "Best semester yet" and the coasting row are both
/// eligible to render) with hand-picked totals — `cgpa`/`totalQualityPoints`
/// are independent fields on `AcademicStanding`, not derived from
/// `semesters`, so these numbers are exactly what `ProjectionSolver` sees;
/// nothing here depends on `CgpaEngine.computeStanding`'s own arithmetic.
AcademicStanding _standing({
  required double cgpa,
  required double bestSemesterGpa,
  int earnedCredits = 40,
}) =>
    AcademicStanding(
      cgpa: cgpa,
      totalQualityPoints: cgpa * earnedCredits,
      totalCreditUnits: earnedCredits,
      totalCreditsPassed: earnedCredits,
      semesters: [
        SemesterComputation(
          semesterId: 's1',
          level: 100,
          term: SemesterTerm.first,
          session: '2023/2024',
          qualityPoints: bestSemesterGpa * (earnedCredits / 2),
          creditUnits: (earnedCredits / 2).round(),
          creditsPassed: (earnedCredits / 2).round(),
          gpa: bestSemesterGpa,
        ),
        SemesterComputation(
          semesterId: 's2',
          level: 100,
          term: SemesterTerm.second,
          session: '2023/2024',
          qualityPoints: cgpa * earnedCredits - bestSemesterGpa * (earnedCredits / 2),
          creditUnits: (earnedCredits / 2).round(),
          creditsPassed: (earnedCredits / 2).round(),
          gpa: (cgpa * earnedCredits - bestSemesterGpa * (earnedCredits / 2)) /
              (earnedCredits / 2),
        ),
      ],
    );

/// `semestersRemainingFor` is calendar-based (graduation year minus today),
/// so this pins it to exactly 4 regardless of when the suite runs.
StudentProfile _profileWithFourSemestersLeft() => StudentProfile(
      fullName: 'Ada Obi',
      regNumber: '20211258122',
      department: 'Computer Science',
      currentLevel: 300,
      entryYear: DateTime.now().year - 2,
      expectedGraduationYear: DateTime.now().year + 2,
    );

Future<Widget> _app(AcademicStanding standing) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await DriftProfileRepository(db.profileDao).saveProfile(_profileWithFourSemestersLeft());

  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      academicRecordProvider.overrideWith(
        (ref) => AcademicRecordController.seeded(
          AcademicRecord(semesters: const [], scheme: defaultSchemes['futo']!),
        ),
      ),
      standingProvider.overrideWithValue(standing),
    ],
    child: const MaterialApp(home: GoalSettingScreen()),
  );
}

Future<void> _selectTarget(WidgetTester tester, String bandLabel) async {
  await tester.tap(find.byKey(const ValueKey('targetPickerFieldTap')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(bandLabel).last);
  await tester.pumpAndSettle();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
      'shows the solved required average, not the band minimum threshold',
      (tester) async {
    // cgpa 2.0, target Second Class Lower (2.40 minimum) with 4 semesters
    // (80 credits) remaining against 40 earned: required works out to
    // 2.60, not the 2.40 band minimum the old mockup showed.
    await tester.pumpWidget(await _app(_standing(cgpa: 2.0, bestSemesterGpa: 3.0)));
    await tester.pumpAndSettle();
    await _selectTarget(tester, 'Second Class Honours (Lower Division)');

    expect(find.text('2.60 GPA'), findsOneWidget);
    expect(find.text('2.40 GPA'), findsNothing);
  });

  testWidgets('secured: current CGPA already at or above the target',
      (tester) async {
    await tester.pumpWidget(await _app(_standing(cgpa: 4.0, bestSemesterGpa: 4.2)));
    await tester.pumpAndSettle();
    await _selectTarget(tester, 'Second Class Honours (Upper Division)');

    expect(find.text('Already secured'), findsOneWidget);
  });

  testWidgets('within reach: above current CGPA but at or below personal best',
      (tester) async {
    await tester.pumpWidget(await _app(_standing(cgpa: 2.0, bestSemesterGpa: 3.0)));
    await tester.pumpAndSettle();
    await _selectTarget(tester, 'Second Class Honours (Lower Division)');

    expect(find.text('Within reach'), findsOneWidget);
  });

  testWidgets('demanding: above current CGPA and above personal best',
      (tester) async {
    await tester.pumpWidget(await _app(_standing(cgpa: 2.5, bestSemesterGpa: 3.2)));
    await tester.pumpAndSettle();
    await _selectTarget(tester, 'Second Class Honours (Upper Division)');

    expect(find.text('Demanding'), findsOneWidget);
  });

  testWidgets('extremely demanding: required average near the scheme maximum',
      (tester) async {
    await tester.pumpWidget(await _app(_standing(cgpa: 3.6, bestSemesterGpa: 3.8)));
    await tester.pumpAndSettle();
    await _selectTarget(tester, 'First Class Honours');

    expect(find.text('Extremely demanding'), findsOneWidget);
  });

  testWidgets(
      'unreachable surfaces the nearest achievable band and "Set this instead" '
      'switches the picker to it', (tester) async {
    await tester.pumpWidget(await _app(_standing(cgpa: 2.0, bestSemesterGpa: 2.2)));
    await tester.pumpAndSettle();
    await _selectTarget(tester, 'First Class Honours');

    expect(find.text('Not reachable now'), findsOneWidget);
    expect(
      find.text('Second Class Honours (Upper Division) is still open'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Set this instead'));
    await tester.tap(find.text('Set this instead'));
    await tester.pumpAndSettle();

    // The picker field itself now reflects the pivoted-to band, and the
    // unreachable card is gone.
    expect(find.text('Second Class Honours (Upper Division)'), findsOneWidget);
    expect(find.text('Not reachable now'), findsNothing);
  });

  testWidgets('changing the target live-recalculates the required average',
      (tester) async {
    await tester.pumpWidget(await _app(_standing(cgpa: 2.0, bestSemesterGpa: 3.0)));
    await tester.pumpAndSettle();

    await _selectTarget(tester, 'Second Class Honours (Lower Division)');
    await tester.pumpAndSettle();
    expect(find.text('2.60 GPA'), findsOneWidget);

    await _selectTarget(tester, 'Second Class Honours (Upper Division)');
    await tester.pumpAndSettle();

    expect(find.text('2.60 GPA'), findsNothing);
    // target 3.50: required = 1.5*3.5 - 0.5*2.0 = 4.25.
    expect(find.text('4.25 GPA'), findsOneWidget);
  });
}

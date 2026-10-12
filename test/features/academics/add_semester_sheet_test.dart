/// Regression coverage for a real, reported data-loss bug: this sheet is
/// the normal, everyday "Add a semester" action from the Academics tab (and
/// Dashboard) -- reachable only once a student is fully signed in and
/// onboarded -- yet it used to hardcode `AppConstants.localProfileId` on
/// every new semester regardless of that. `AuthNotifier._stateFor` deletes
/// anything still sitting under that placeholder on the student's very next
/// sign-in/session-restore once their real uid already has other semesters,
/// since that's meant to catch a stray pre-auth draft, not a genuinely new
/// entry -- so a student adding, say, their 400L results would find them
/// silently gone the next time they reopened the app.
library;

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/drift_academic_record_repository.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/features/academics/widgets/add_semester_sheet.dart';
import 'package:perform_plus/features/auth/providers/auth_provider.dart';

/// Resolves straight to a signed-in uid, bypassing `_stateFor`'s Drift/
/// session plumbing -- this test only needs an authenticated uid to exist
/// in [authStateProvider], not to exercise how it got there.
class _FakeSignedInAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const AuthState(userId: 'student-uid', email: 'student@example.com');
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
      'saving a new semester from the Academics tab tags it with the '
      'signed-in uid, not the onboarding placeholder', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    // Awaited BEFORE the first pump -- matches what the real app's router
    // redirect guarantees (a signed-in-only screen like this is never
    // reachable until `authStateProvider.hasValue`; see app_router.dart).
    // Pumping into a plain `ProviderScope(overrides: ...)` instead would
    // leave `authStateProvider` in its initial microtask of `AsyncLoading`,
    // which has nothing to do with the bug this test guards against.
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authStateProvider.overrideWith(_FakeSignedInAuthNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authStateProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const ValueKey('openSheet'),
                  onPressed: () => showAddSemesterSheet(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('openSheet')));
    await tester.pumpAndSettle();

    // Level/term/session already default to sensible values -- only the
    // course row needs filling in. `TextFormField` index 0 is the sheet's
    // own Session field, index 1 is the row's course code, index 2 is the
    // row's optional course title. `DropdownButtonFormField<int>` index 0
    // is the sheet's Level picker, index 1 is the row's Units picker.
    await tester.enterText(find.byType(TextFormField).at(1), 'CSC101');
    await tester.tap(find.byType(DropdownButtonFormField<int>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();

    // The sheet is taller than the test viewport once a row is filled in --
    // scroll "Save semester" into view before tapping it.
    await tester.dragUntilVisible(
      find.text('Save semester'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save semester'));
    await tester.pumpAndSettle();
    // `AcademicRecordController.addSemester` fires its Drift write via an
    // un-awaited `_persist()` -- give that microtask a chance to land
    // before reading straight from the database below.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));

    final repo = DriftAcademicRecordRepository(db.semesterDao, db.courseResultDao);
    final saved = await repo.loadSemesters();
    expect(saved, hasLength(1));
    expect(
      saved.single.profileId,
      'student-uid',
      reason: 'a semester added while signed in must be tagged with the '
          'real uid, never AppConstants.localProfileId',
    );
  });
}

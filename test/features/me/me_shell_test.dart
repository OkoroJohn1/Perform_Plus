import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:perform_plus/core/router/routes.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/academic_record_provider.dart';
import 'package:perform_plus/data/repositories/achievement_provider.dart';
import 'package:perform_plus/data/repositories/note_provider.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/data/seed/nigerian_institutions.dart';
import 'package:perform_plus/domain/models/achievement.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/domain/models/grading_scheme.dart';
import 'package:perform_plus/features/auth/providers/auth_provider.dart';
import 'package:perform_plus/features/me/screens/me_shell.dart';
import 'package:perform_plus/shared/widgets/badge_shield.dart';

/// `authStateProvider`'s real implementation touches `Supabase.instance` --
/// never initialized in a plain `flutter test` run. `signOut()` here just
/// records the call instead of touching the network, same reason
/// `sign_in_screen_test.dart` does this for sign-in.
class _FakeAuthNotifier extends AuthNotifier {
  final String? provider;
  bool signOutCalled = false;

  _FakeAuthNotifier({this.provider});

  @override
  Future<AuthState> build() async =>
      AuthState(userId: 'u1', email: 'ada@example.com', provider: provider);

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    state = const AsyncValue.data(AuthState.signedOut);
  }
}

/// `AppDatabase.wipeLocalData` is a plain method (not code-generated), so a
/// subclass can override it to record whether the destructive path actually
/// ran, without touching a real in-memory schema at all.
class _TrackingDatabase extends AppDatabase {
  bool wiped = false;

  _TrackingDatabase() : super.forTesting(NativeDatabase.memory());

  @override
  Future<void> wipeLocalData(String profileId) async {
    wiped = true;
  }
}

final _scheme = defaultSchemes['futo']!.copyWith(repeatPolicy: RepeatPolicy.countBothAttempts);

CourseResult _r(String code, int unit, String grade, String semesterId, {int attempt = 1}) =>
    CourseResult(
      id: '$semesterId-$code-$attempt',
      semesterId: semesterId,
      courseCode: code,
      creditUnit: unit,
      grade: grade,
      attempt: attempt,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

/// Mirrors `cgpa_engine_test.dart`'s `failThenRepeat` fixture -- a proven
/// scenario where `countBothAttempts` yields 3.00 and `replaceOriginal`
/// yields 4.50, so switching the policy produces a real, checkable delta.
final _failThenRepeat = [
  Semester(
    id: 's1',
    profileId: 'local-profile',
    session: '2023/2024',
    term: SemesterTerm.first,
    level: 100,
    results: [_r('MTH101', 3, 'F', 's1'), _r('CSC101', 3, 'A', 's1')],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  ),
  Semester(
    id: 's2',
    profileId: 'local-profile',
    session: '2024/2025',
    term: SemesterTerm.first,
    level: 200,
    results: [_r('MTH101', 3, 'B', 's2', attempt: 2)],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  ),
];

/// No profile row is seeded in the in-memory db, so `studentProfileProvider`
/// -- deliberately left un-overridden, using its real Drift-backed
/// `ProfileController` -- resolves to null and the identity card falls
/// back to "Add your profile". None of these tests exercise the profile
/// card's populated state.
ProviderContainer _containerFor({
  required AcademicRecord record,
  Map<BadgeId, DateTime> achievements = const {},
  _FakeAuthNotifier? authNotifier,
  _TrackingDatabase? db,
}) {
  return ProviderContainer(
    overrides: [
      academicRecordProvider.overrideWith((ref) => AcademicRecordController.seeded(record)),
      notesProvider.overrideWith((ref) => NotesController.seeded(const NotesState())),
      achievementsProvider.overrideWith((ref) => AchievementsController.seeded(achievements)),
      authStateProvider.overrideWith(() => authNotifier ?? _FakeAuthNotifier()),
      appDatabaseProvider.overrideWithValue(db ?? _TrackingDatabase()),
    ],
  );
}

Widget _app(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(path: Routes.home, builder: (_, __) => const MeShell()),
      GoRoute(path: Routes.splash, builder: (_, __) => const SizedBox()),
      GoRoute(path: Routes.profileSetup, builder: (_, __) => const SizedBox()),
      GoRoute(path: Routes.academics, builder: (_, __) => const SizedBox()),
      GoRoute(path: Routes.ai, builder: (_, __) => const SizedBox()),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    // The identity card and section illustrations rely on perpetual
    // animations suppressed under reduced motion -- pumpAndSettle never
    // settles against one otherwise. Reusing the ambient MediaQueryData
    // (via copyWith) matters: a bare `const MediaQueryData(...)` defaults
    // `size` to `Size.zero`, which silently breaks the grading-scheme
    // sheet's `MediaQuery.of(context).size.height`-based max height.
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
}

/// The screen is far taller than the test viewport, and `ListView`'s
/// sliver protocol only keeps near-viewport children built -- scrolling
/// straight to the bottom (a fixed large offset) disposes middle content
/// like the Academic section entirely rather than revealing it.
/// `scrollUntilVisible` scrolls incrementally and stops the moment the
/// target is actually built, which is what a fixed-offset drag can't do
/// reliably on a screen this long.
Future<void> _scrollToKey(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(
    find.byKey(ValueKey(key)),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollToText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('locked achievement badges', () {
    testWidgets('a day-one user sees every badge locked, with its criteria stated',
        (tester) async {
      final container = _containerFor(
        record: AcademicRecord(semesters: const [], scheme: fallbackScheme),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();

      expect(find.text('7-day reading streak'), findsOneWidget);
      expect(find.text('Semester GPA above 4.0'), findsOneWidget);
      expect(find.text('GPA up 0.5 in a semester'), findsOneWidget);
      expect(find.text('Add your first result'), findsOneWidget);

      final shields = tester.widgetList<BadgeShield>(find.byType(BadgeShield));
      expect(shields.length, 4);
      expect(shields.every((s) => !s.unlocked), isTrue);
    });
  });

  testWidgets('the grading scheme row shows an Unverified chip for an unverified scheme',
      (tester) async {
    final container = _containerFor(
      record: AcademicRecord(semesters: const [], scheme: _scheme.copyWith(isVerified: false)),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    await _scrollToKey(tester, 'gradingSchemeRow');

    expect(find.text('Unverified'), findsOneWidget);
  });

  testWidgets('a verified scheme shows no Unverified chip', (tester) async {
    final container = _containerFor(
      record: AcademicRecord(semesters: const [], scheme: _scheme.copyWith(isVerified: true)),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    await _scrollToKey(tester, 'gradingSchemeRow');

    expect(find.text('Unverified'), findsNothing);
  });

  testWidgets('changing the carryover policy shows the recalculation delta and applies it',
      (tester) async {
    final container = _containerFor(
      record: AcademicRecord(semesters: _failThenRepeat, scheme: _scheme),
    );
    addTearDown(container.dispose);

    // The grading scheme sheet has a lot of content (grade points,
    // classification bands, three policy options, a save button) -- the
    // default 800x600 test surface is too short to fit it even after
    // scrolling, leaving the last few widgets a few pixels past the
    // viewport edge. A taller surface sidesteps that instead of fighting
    // scroll-precision in the test.
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    await _scrollToKey(tester, 'gradingSchemeRow');

    await tester.tap(find.byKey(const ValueKey('gradingSchemeRow')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('repeatPolicy_replaceOriginal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('repeatPolicy_replaceOriginal')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('saveGradingSchemeTap')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('saveGradingSchemeTap')));
    await tester.pumpAndSettle();

    expect(find.text('Change repeat policy?'), findsOneWidget);
    expect(find.textContaining('3.00 → 4.50'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirmPolicyChangeTap')));
    await tester.pumpAndSettle();

    expect(container.read(academicRecordProvider).scheme.repeatPolicy, RepeatPolicy.replaceOriginal);
    expect(container.read(standingProvider).cgpa, 4.50);
  });

  group('Change password row', () {
    testWidgets('is hidden for a Google-only account', (tester) async {
      final container = _containerFor(
        record: AcademicRecord(semesters: const [], scheme: _scheme),
        authNotifier: _FakeAuthNotifier(provider: 'google'),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _scrollToKey(tester, 'gradingSchemeRow');

      expect(find.byKey(const ValueKey('changePasswordRow')), findsNothing);
    });

    testWidgets('is shown for an email/password account', (tester) async {
      final container = _containerFor(
        record: AcademicRecord(semesters: const [], scheme: _scheme),
        authNotifier: _FakeAuthNotifier(provider: 'email'),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _scrollToKey(tester, 'changePasswordRow');

      expect(find.byKey(const ValueKey('changePasswordRow')), findsOneWidget);
    });
  });

  testWidgets('deleting the account requires typing DELETE before the button is enabled',
      (tester) async {
    final auth = _FakeAuthNotifier();
    final db = _TrackingDatabase();
    final container = _containerFor(
      record: AcademicRecord(semesters: _failThenRepeat, scheme: _scheme),
      authNotifier: auth,
      db: db,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    await _scrollToKey(tester, 'deleteAccountRow');

    await tester.tap(find.byKey(const ValueKey('deleteAccountRow')));
    await tester.pumpAndSettle();

    FilledButton confirmButton() =>
        tester.widget<FilledButton>(find.byKey(const ValueKey('deleteAccountConfirmTap')));

    expect(confirmButton().onPressed, isNull);
    expect(db.wiped, isFalse);

    await tester.enterText(find.byKey(const ValueKey('deleteAccountConfirmField')), 'delete');
    await tester.pumpAndSettle();
    expect(confirmButton().onPressed, isNull, reason: 'must match DELETE exactly, case-sensitive');

    await tester.enterText(find.byKey(const ValueKey('deleteAccountConfirmField')), 'DELETE');
    await tester.pumpAndSettle();
    expect(confirmButton().onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('deleteAccountConfirmTap')));
    await tester.pumpAndSettle();

    expect(db.wiped, isTrue);
    expect(auth.signOutCalled, isTrue);
  });

  group('sign-out confirmation', () {
    testWidgets('a plain sign-out (box left unchecked) preserves local data', (tester) async {
      final auth = _FakeAuthNotifier();
      final db = _TrackingDatabase();
      final container = _containerFor(
        record: AcademicRecord(semesters: const [], scheme: fallbackScheme),
        authNotifier: auth,
        db: db,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _scrollToText(tester, 'Sign out');

      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('signOutConfirmTap')));
      await tester.pumpAndSettle();

      expect(auth.signOutCalled, isTrue);
      expect(db.wiped, isFalse);
      // The destructive second dialog never appears on this path.
      expect(find.text('Remove your data?'), findsNothing);
    });

    testWidgets('the destructive path requires a second, explicitly-named confirmation',
        (tester) async {
      final auth = _FakeAuthNotifier();
      final db = _TrackingDatabase();
      final semesters = [
        Semester(
          id: 's1',
          profileId: 'local-profile',
          session: '2023/2024',
          term: SemesterTerm.first,
          level: 100,
          results: [
            CourseResult(
              id: 'r1',
              semesterId: 's1',
              courseCode: 'CSC101',
              creditUnit: 3,
              grade: 'A',
              createdAt: DateTime(2024),
              updatedAt: DateTime(2024),
            ),
          ],
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];
      final container = _containerFor(
        record: AcademicRecord(semesters: semesters, scheme: fallbackScheme),
        authNotifier: auth,
        db: db,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _scrollToText(tester, 'Sign out');

      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();

      // Check the "also remove my data" box, then hit the first dialog's
      // own Sign out button -- this must NOT sign out yet.
      await tester.tap(find.byKey(const ValueKey('removeDataOnSignOutCheckbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('signOutConfirmTap')));
      await tester.pumpAndSettle();

      expect(auth.signOutCalled, isFalse);
      expect(db.wiped, isFalse);
      expect(find.text('Remove your data?'), findsOneWidget);
      expect(find.textContaining('1 semester, 1 result and 0 notes'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('destructiveSignOutConfirmTap')));
      await tester.pumpAndSettle();

      expect(db.wiped, isTrue);
      expect(auth.signOutCalled, isTrue);
    });
  });
}

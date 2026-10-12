/// Covers the deleted-account path: an invalid/expired refresh token (how
/// Supabase actually surfaces a server-side-deleted account — it never
/// pushes a dedicated event) must be told apart from a genuine, explicit
/// `signOut()`, must never touch local academic data, and must flag the
/// account-deleted message rather than leaving the app silently stuck.
///
/// `SupabaseClient`/`GoTrueClient` is real, heavyweight infrastructure with
/// no way to trigger a rejected-refresh-token event on demand — this drives
/// `AuthNotifier` through its `authChangeStream()`/`currentUserSeam()` test
/// seams instead, exercising the SAME listener logic `build()` really runs.
library;

import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/core/constants/app_constants.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as gotrue;

/// A real signed-in event, as opposed to [_StreamDrivenAuthNotifier
/// .seedSignedIn]'s shortcut -- this is what actually drives
/// `AuthNotifier._stateFor`, the reassign/discard logic under test below.
/// `User`/`Session` have several required fields with no test-friendly
/// default, hence the minimal literal values here.
gotrue.AuthState _signedInEvent(String uid) {
  final user = User(
    id: uid,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime(2024).toIso8601String(),
  );
  return gotrue.AuthState(
    AuthChangeEvent.signedIn,
    Session(accessToken: 'test-token', tokenType: 'bearer', user: user),
  );
}

class _StreamDrivenAuthNotifier extends AuthNotifier {
  final events = StreamController<gotrue.AuthState>.broadcast();

  @override
  Stream<gotrue.AuthState> authChangeStream() => events.stream;

  // No real client to read a cached user from in a test -- every state
  // this test cares about is reached purely by pushing stream events.
  @override
  User? currentUserSeam() => null;

  /// Test-only: jumps straight to an already-resolved signed-in state, the
  /// way a real session would look, without constructing a real (many
  /// required fields) `User` object just to populate `userId`.
  void seedSignedIn(String uid) {
    state = AsyncValue.data(AuthState(userId: uid, email: '$uid@example.com'));
  }
}

Semester _semester(String profileId, {String id = 'sem-1', int level = 100}) => Semester(
      id: id,
      profileId: profileId,
      session: '2023/2024',
      term: SemesterTerm.first,
      level: level,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late _StreamDrivenAuthNotifier notifier;

  setUp(() async {
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(
          AppDatabase.forTesting(NativeDatabase.memory()),
        ),
        authStateProvider.overrideWith(_StreamDrivenAuthNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authStateProvider.future);
    notifier = container.read(authStateProvider.notifier) as _StreamDrivenAuthNotifier;
  });

  test(
    'an invalid-refresh-token signOut is treated as a deleted account -- '
    'signs out, flags the message, and leaves local results untouched',
    () async {
      notifier.seedSignedIn('deleted-uid');
      await container
          .read(academicRecordRepositoryProvider)
          .addSemester(_semester('deleted-uid'));

      notifier.events.add(
        const gotrue.AuthState(
          AuthChangeEvent.signedOut,
          null,
          signOutReason: SignOutReason.sessionExpired,
        ),
      );
      // Flush the async handler (Drift read/write, best-effort
      // secure-storage clear) to completion.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authStateProvider).value, AuthState.signedOut);
      expect(container.read(accountDeletedProvider), isTrue);

      final stillThere = await container
          .read(academicRecordRepositoryProvider)
          .hasSemestersForProfile('deleted-uid');
      expect(
        stillThere,
        isTrue,
        reason: 'a deleted account must never delete local results',
      );
    },
  );

  test(
    'a plain, explicit signOut does NOT flag the account-deleted message',
    () async {
      notifier.seedSignedIn('still-active-uid');

      notifier.events.add(
        const gotrue.AuthState(
          AuthChangeEvent.signedOut,
          null,
          signOutReason: SignOutReason.userInitiated,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authStateProvider).value, AuthState.signedOut);
      expect(container.read(accountDeletedProvider), isFalse);
    },
  );

  test(
    'a sign-up after a deleted account offers to reattach the orphaned '
    'local data, and attaching moves it onto the new uid',
    () async {
      notifier.seedSignedIn('deleted-uid');
      await container
          .read(academicRecordRepositoryProvider)
          .addSemester(_semester('deleted-uid'));

      notifier.events.add(
        const gotrue.AuthState(
          AuthChangeEvent.signedOut,
          null,
          signOutReason: SignOutReason.sessionExpired,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Simulate the next successful sign-up landing on a brand new uid.
      notifier.seedSignedIn('new-uid');
      // ignore: invalid_use_of_protected_member
      await notifier.checkForOrphanedLocalData('new-uid');

      expect(container.read(pendingLocalDataAttachProvider), 'deleted-uid');

      await container.read(authStateProvider.notifier).attachOrphanedLocalData();

      expect(container.read(pendingLocalDataAttachProvider), isNull);
      final repo = container.read(academicRecordRepositoryProvider);
      expect(await repo.hasSemestersForProfile('deleted-uid'), isFalse);
      expect(await repo.hasSemestersForProfile('new-uid'), isTrue);
    },
  );

  test(
    'a real, newly-added semester tagged with the signed-in uid survives '
    'the next sign-in/session-restore, while a stray semester left under '
    'the onboarding placeholder is still correctly discarded',
    () async {
      final repo = container.read(academicRecordRepositoryProvider);

      // First sign-in: nothing exists anywhere yet, so AuthNotifier._stateFor
      // reassigns (a no-op here) rather than discards.
      notifier.events.add(_signedInEvent('student-uid'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authStateProvider).value?.userId, 'student-uid');

      // The FIXED behaviour: `add_semester_sheet.dart`/`backfill_screen
      // .dart` now tag a brand-new, post-auth semester with the real uid.
      await repo.addSemester(_semester('student-uid', id: 'real-new-sem', level: 400));

      // The OLD, BUGGY behaviour, reproduced directly: something still
      // manages to leave a semester under the onboarding placeholder after
      // the account is already established -- `_stateFor` must still treat
      // this one as the stray pre-auth duplicate it's designed to catch.
      await repo.addSemester(
        _semester(AppConstants.localProfileId, id: 'stray-placeholder-sem', level: 100),
      );

      // Simulate the student reopening the app -- a second auth resolution
      // for the SAME uid, exactly what used to wipe a just-added semester.
      notifier.events.add(_signedInEvent('student-uid'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final remaining = await repo.loadSemesters();
      expect(
        remaining.map((s) => s.id),
        contains('real-new-sem'),
        reason: 'a semester correctly tagged with the real uid must never '
            'be deleted just because this uid already has other data',
      );
      expect(
        remaining.map((s) => s.id),
        isNot(contains('stray-placeholder-sem')),
        reason: 'a semester still left under the onboarding placeholder is '
            'a genuine stray duplicate and must still be discarded',
      );
    },
  );
}

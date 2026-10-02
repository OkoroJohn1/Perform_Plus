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
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/domain/models/course_result.dart';
import 'package:perform_plus/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as gotrue;

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

Semester _semester(String profileId) => Semester(
      id: 'sem-1',
      profileId: profileId,
      session: '2023/2024',
      term: SemesterTerm.first,
      level: 100,
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
}

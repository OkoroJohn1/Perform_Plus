import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/data/repositories/profile_remote_sync.dart';
import 'package:perform_plus/features/auth/providers/auth_provider.dart';
import 'package:perform_plus/features/auth/providers/profile_provider.dart';

/// Records exactly what it was asked to do. `ProfileRemoteSync`'s only
/// method is `updateProfile` — there is no `insertProfile` on the
/// interface at all, so a caller structurally cannot ask this fake (or the
/// real Supabase implementation) to insert; this test additionally checks
/// it was actually invoked, with the right uid, rather than skipped.
class _RecordingProfileRemoteSync implements ProfileRemoteSync {
  String? uidReceived;
  StudentProfile? profileReceived;
  int callCount = 0;

  @override
  Future<void> updateProfile(String uid, StudentProfile profile) async {
    callCount++;
    uidReceived = uid;
    profileReceived = profile;
  }
}

class _SignedInAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const AuthState(userId: 'auth-uid-123', profileComplete: false);
}

class _SignedOutAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => AuthState.signedOut;
}

const _profile = StudentProfile(
  fullName: 'Ada Obi',
  regNumber: '20211258122',
  department: 'Computer Science',
  currentLevel: 300,
  entryYear: 2021,
  expectedGraduationYear: 2026,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('save() mirrors to Supabase via UPDATE when a session exists', () async {
    final remoteSync = _RecordingProfileRemoteSync();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(
          AppDatabase.forTesting(NativeDatabase.memory()),
        ),
        authStateProvider.overrideWith(_SignedInAuthNotifier.new),
        profileRemoteSyncProvider.overrideWithValue(remoteSync),
      ],
    );
    addTearDown(container.dispose);
    // Let the overridden authStateProvider resolve before saving, same as
    // the real app would have a resolved session by the time this screen
    // is reachable.
    await container.read(authStateProvider.future);

    await container.read(studentProfileProvider.notifier).save(_profile);

    expect(remoteSync.callCount, 1);
    expect(remoteSync.uidReceived, 'auth-uid-123');
    expect(remoteSync.profileReceived?.regNumber, '20211258122');

    // Local Drift always gets the write too, regardless of the remote call.
    final persisted =
        await container.read(profileRepositoryProvider).loadProfile();
    expect(persisted?.fullName, 'Ada Obi');
  });

  test('save() completes and persists locally with no session, never syncing',
      () async {
    final remoteSync = _RecordingProfileRemoteSync();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(
          AppDatabase.forTesting(NativeDatabase.memory()),
        ),
        authStateProvider.overrideWith(_SignedOutAuthNotifier.new),
        profileRemoteSyncProvider.overrideWithValue(remoteSync),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authStateProvider.future);

    await container.read(studentProfileProvider.notifier).save(_profile);

    expect(remoteSync.callCount, 0);
    final persisted =
        await container.read(profileRepositoryProvider).loadProfile();
    expect(persisted?.fullName, 'Ada Obi');
  });

  test('a failing remote sync never surfaces from save() — local data is safe',
      () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(
          AppDatabase.forTesting(NativeDatabase.memory()),
        ),
        authStateProvider.overrideWith(_SignedInAuthNotifier.new),
        profileRemoteSyncProvider.overrideWithValue(_ThrowingProfileRemoteSync()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authStateProvider.future);

    await container.read(studentProfileProvider.notifier).save(_profile);

    final persisted =
        await container.read(profileRepositoryProvider).loadProfile();
    expect(persisted?.fullName, 'Ada Obi');
  });
}

class _ThrowingProfileRemoteSync implements ProfileRemoteSync {
  @override
  Future<void> updateProfile(String uid, StudentProfile profile) async {
    throw Exception('network unreachable');
  }
}

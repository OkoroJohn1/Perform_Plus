/// Student profile provider — kept separate from [AuthState], which is
/// auth-only. The [StudentProfile] model itself lives in
/// `lib/domain/models/student_profile.dart` (pure Dart) so
/// `lib/domain/repositories/profile_repository.dart` can reference it
/// without depending on this feature folder. Persisted via
/// [ProfileRepository] so it survives restarts.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/student_profile.dart';
import '../../../domain/repositories/profile_repository.dart';
import 'auth_provider.dart';

export '../../../domain/models/student_profile.dart';

class ProfileController extends StateNotifier<StudentProfile?> {
  final Ref _ref;
  final ProfileRepository _repository;

  /// Mirrors `academic_record_provider.dart`/`note_provider.dart`'s own
  /// `ready` future -- a screen that does a one-time synchronous
  /// `ref.read(studentProfileProvider)` right on `initState` (Profile
  /// Setup's edit-mode pre-fill, in particular) can otherwise race this
  /// controller's own async Drift read on a cold start and see `null` even
  /// though a real profile row exists, rendering a blank form the student
  /// then unknowingly overwrites their real data by saving.
  late final Future<void> ready;

  ProfileController(this._ref, this._repository) : super(null) {
    ready = _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final persisted = await _repository.loadProfile();
    if (persisted != null) state = persisted;
    // A photo row can survive on this same device while the file it points
    // to doesn't (storage cleared, restored from a partial backup, etc.) --
    // restore it from the Storage backup rather than leaving a permanently
    // broken avatar. A brand-new device has no local profile row at all, so
    // this deliberately doesn't try to conjure one from just a photo.
    final path = persisted?.photoPath;
    if (path != null && !await File(path).exists()) {
      unawaited(_restorePhotoIfPossible(path));
    }
  }

  Future<void> _restorePhotoIfPossible(String path) async {
    final uid = _ref.read(authStateProvider).valueOrNull?.userId;
    if (uid == null) return;
    final sync = _ref.read(profilePhotoRemoteSyncProvider);
    if (sync == null) return;
    final bytes = await sync.downloadPhoto(uid);
    if (bytes == null) return;
    try {
      await File(path).create(recursive: true);
      await File(path).writeAsBytes(bytes, flush: true);
    } catch (_) {
      // Best-effort -- an unwritable path is left as it was.
    }
  }

  /// Local Drift first, always — the profile screen must complete with no
  /// connectivity. The Supabase mirror is attempted only when a session
  /// exists, and any failure there is swallowed rather than surfaced: it
  /// queues for a future sync pass rather than blocking the student, who
  /// already has the data safe locally.
  Future<void> save(StudentProfile profile) async {
    final previousPhoto = state?.photoPath;
    state = profile;
    await _repository.saveProfile(profile);

    final uid = _ref.read(authStateProvider).valueOrNull?.userId;
    if (uid == null) return;
    try {
      await _ref.read(profileRemoteSyncProvider).updateProfile(uid, profile);
    } catch (_) {
      // TODO(v1): a real outbox/retry queue once the sync layer exists.
      // For now, the next successful `save()` (or app launch, once startup
      // sync exists) will simply resend the current profile.
    }

    final sync = _ref.read(profilePhotoRemoteSyncProvider);
    if (sync == null) return;
    if (profile.photoPath != null) {
      unawaited(sync.backupPhoto(uid, profile.photoPath!));
    } else if (previousPhoto != null) {
      unawaited(sync.deletePhotoBackup(uid));
    }
  }
}

final studentProfileProvider = StateNotifierProvider<ProfileController, StudentProfile?>(
  (ref) => ProfileController(ref, ref.watch(profileRepositoryProvider)),
);

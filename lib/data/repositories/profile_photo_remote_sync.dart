/// Backs up the one local profile photo (see `profile_photo_store.dart` --
/// there is only ever a single file, always JPEG) to Supabase Storage's
/// private `profile-photos` bucket, keyed `<uid>/photo.jpg`. Mirrors
/// `note_remote_sync.dart`'s shape: local disk is always the source of
/// truth for reading, every method here is best-effort and swallows its
/// own errors, and this is what survives an uninstall or a new device --
/// without it, a profile photo exists only in this app's local sandboxed
/// storage.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

const _profilePhotosBucket = 'profile-photos';

abstract class ProfilePhotoRemoteSync {
  /// Uploads the photo at [filePath]. Never throws; returns whether it
  /// succeeded, purely for logging/testing -- callers don't act on it.
  Future<bool> backupPhoto(String uid, String filePath);

  /// The backed-up photo's bytes, or `null` if there's none or the
  /// download fails.
  Future<Uint8List?> downloadPhoto(String uid);

  Future<void> deletePhotoBackup(String uid);
}

class SupabaseProfilePhotoRemoteSync implements ProfilePhotoRemoteSync {
  final SupabaseClient _client;

  SupabaseProfilePhotoRemoteSync(this._client);

  @override
  Future<bool> backupPhoto(String uid, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      await _client.storage.from(_profilePhotosBucket).uploadBinary(
            '$uid/photo.jpg',
            await file.readAsBytes(),
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Uint8List?> downloadPhoto(String uid) async {
    try {
      return await _client.storage.from(_profilePhotosBucket).download('$uid/photo.jpg');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deletePhotoBackup(String uid) async {
    try {
      await _client.storage.from(_profilePhotosBucket).remove(['$uid/photo.jpg']);
    } catch (_) {
      // Best-effort -- an orphaned backup file is a storage-quota nuisance,
      // never something worth surfacing to the student.
    }
  }
}

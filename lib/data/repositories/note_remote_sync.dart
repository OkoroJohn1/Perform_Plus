/// Backs up an uploaded note's file (and just enough metadata to rebuild
/// the `Note` row) to Supabase Storage's private `note-files` bucket, keyed
/// `<uid>/<noteId>.<ext>` plus a `<uid>/<noteId>.json` sidecar. Local Drift
/// is always the source of truth for reading -- every method here is
/// best-effort and swallows its own errors, since a failed backup must
/// never block or break the upload/delete flow it rides along with. This
/// is what makes an uninstall/new-device actually survivable: without it,
/// the notes/flashcards/past-questions a student uploads exist only in
/// this app's local sandboxed storage, gone the moment the app is removed.
///
/// Reading progress (`NotePage`/`ReadingSession` rows) is deliberately NOT
/// backed up here -- restoring the document itself is the durability win
/// that matters; re-establishing exactly which pages were read is a
/// smaller loss on a genuinely new device and out of scope for this pass.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/note.dart';

const _noteFilesBucket = 'note-files';

class BackedUpNote {
  final String noteId;
  final String title;
  final NoteFileType fileType;
  final int totalPages;
  final NoteCategory category;
  final String? courseCode;
  final int? examYear;
  final DateTime uploadedAt;
  final String fileExt;
  final Uint8List fileBytes;

  const BackedUpNote({
    required this.noteId,
    required this.title,
    required this.fileType,
    required this.totalPages,
    required this.category,
    required this.courseCode,
    required this.examYear,
    required this.uploadedAt,
    required this.fileExt,
    required this.fileBytes,
  });
}

abstract class NoteRemoteSync {
  /// Uploads [note]'s file plus a metadata sidecar. Returns the storage
  /// path to save on the note's `storagePath` field on success, or `null`
  /// on any failure (offline, file missing, etc.) -- never throws.
  Future<String?> backupNote(String uid, Note note);

  /// Every note currently backed up under [uid], fully downloaded and
  /// ready to reconstruct as local `Note` rows. Empty (never throws) if
  /// there's nothing there or the listing/download fails.
  Future<List<BackedUpNote>> listBackedUpNotes(String uid);

  Future<void> deleteNoteBackup(String uid, String noteId, String fileExt);
}

class SupabaseNoteRemoteSync implements NoteRemoteSync {
  final SupabaseClient _client;

  SupabaseNoteRemoteSync(this._client);

  String _extOf(String filePath) {
    final dot = filePath.lastIndexOf('.');
    return dot == -1 ? 'bin' : filePath.substring(dot + 1);
  }

  @override
  Future<String?> backupNote(String uid, Note note) async {
    try {
      final file = File(note.filePath);
      if (!await file.exists()) return null;
      final ext = _extOf(note.filePath);
      final filePath = '$uid/${note.id}.$ext';
      final metaPath = '$uid/${note.id}.json';

      await _client.storage.from(_noteFilesBucket).uploadBinary(
            filePath,
            await file.readAsBytes(),
            fileOptions: const FileOptions(upsert: true),
          );

      final meta = jsonEncode({
        'title': note.title,
        'fileType': note.fileType.name,
        'totalPages': note.totalPages,
        'category': note.category.name,
        'courseCode': note.courseCode,
        'examYear': note.examYear,
        'uploadedAt': note.uploadedAt.toIso8601String(),
        'fileExt': ext,
      });
      await _client.storage.from(_noteFilesBucket).uploadBinary(
            metaPath,
            Uint8List.fromList(utf8.encode(meta)),
            fileOptions: const FileOptions(upsert: true, contentType: 'application/json'),
          );

      return filePath;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<BackedUpNote>> listBackedUpNotes(String uid) async {
    try {
      final objects = await _client.storage.from(_noteFilesBucket).list(path: uid);
      final results = <BackedUpNote>[];
      for (final object in objects) {
        if (!object.name.endsWith('.json')) continue;
        final noteId = object.name.substring(0, object.name.length - '.json'.length);
        try {
          final metaBytes = await _client.storage.from(_noteFilesBucket).download('$uid/${object.name}');
          final meta = jsonDecode(utf8.decode(metaBytes)) as Map<String, dynamic>;
          final ext = meta['fileExt'] as String;
          final fileBytes = await _client.storage.from(_noteFilesBucket).download('$uid/$noteId.$ext');
          results.add(BackedUpNote(
            noteId: noteId,
            title: meta['title'] as String,
            fileType: NoteFileType.values.firstWhere((t) => t.name == meta['fileType']),
            totalPages: meta['totalPages'] as int,
            category: NoteCategory.values.firstWhere((c) => c.name == meta['category'], orElse: () => NoteCategory.note),
            courseCode: meta['courseCode'] as String?,
            examYear: meta['examYear'] as int?,
            uploadedAt: DateTime.parse(meta['uploadedAt'] as String),
            fileExt: ext,
            fileBytes: fileBytes,
          ));
        } catch (_) {
          // One corrupt/partial backup shouldn't sink the rest of the restore.
          continue;
        }
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> deleteNoteBackup(String uid, String noteId, String fileExt) async {
    try {
      await _client.storage.from(_noteFilesBucket).remove(['$uid/$noteId.$fileExt', '$uid/$noteId.json']);
    } catch (_) {
      // Best-effort -- an orphaned backup file is a storage-quota nuisance,
      // never something worth surfacing to the student.
    }
  }
}

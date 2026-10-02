/// The Study tab's e-notes state — mirrors `academic_record_provider.dart`'s
/// shape (a `StateNotifier` backed by Drift, a `.seeded()` test escape
/// hatch, a `ready` future for cold-start awaiting).
library;

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/engine/study_engine.dart';
import '../../domain/models/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'note_remote_sync.dart';
import 'repository_providers.dart';

const _uuid = Uuid();

class NotesState {
  final List<Note> notes;
  final Map<String, int> pagesReadByNote;
  final int totalActiveSeconds;
  final int storedStreak;
  final DateTime? lastReadDate;

  const NotesState({
    this.notes = const [],
    this.pagesReadByNote = const {},
    this.totalActiveSeconds = 0,
    this.storedStreak = 0,
    this.lastReadDate,
  });

  /// The streak as it should read right now — see
  /// `study_engine.dart#effectiveStreak`: a missed day zeroes this out on
  /// read, without ever rewriting [storedStreak] just because time passed.
  int get displayStreak =>
      effectiveStreak(storedStreak: storedStreak, lastReadDate: lastReadDate, today: DateTime.now());

  int pagesReadFor(String noteId) => pagesReadByNote[noteId] ?? 0;

  NotesState copyWith({
    List<Note>? notes,
    Map<String, int>? pagesReadByNote,
    int? totalActiveSeconds,
    int? storedStreak,
    DateTime? lastReadDate,
  }) =>
      NotesState(
        notes: notes ?? this.notes,
        pagesReadByNote: pagesReadByNote ?? this.pagesReadByNote,
        totalActiveSeconds: totalActiveSeconds ?? this.totalActiveSeconds,
        storedStreak: storedStreak ?? this.storedStreak,
        lastReadDate: lastReadDate ?? this.lastReadDate,
      );
}

class NotesController extends StateNotifier<NotesState> {
  final NoteRepository? _repository;
  final NoteRemoteSync? _remoteSync;
  final String? _authUid;

  late final Future<void> ready;

  NotesController(NoteRepository repository, {NoteRemoteSync? remoteSync, String? authUid})
      : _repository = repository,
        _remoteSync = remoteSync,
        _authUid = authUid,
        super(const NotesState()) {
    ready = _load();
  }

  /// Fixed-state constructor for widget tests.
  NotesController.seeded(super.state)
      : _repository = null,
        _remoteSync = null,
        _authUid = null {
    ready = Future.value();
  }

  Future<void> _load() async {
    final repo = _repository;
    if (repo == null) return;
    final notes = await repo.loadNotes();
    final counts = await repo.pagesReadCountByNote();
    final totalSeconds = await repo.totalActiveSeconds();
    final streak = await repo.loadStreak();
    if (!mounted) return;
    state = NotesState(
      notes: notes,
      pagesReadByNote: counts,
      totalActiveSeconds: totalSeconds,
      storedStreak: streak.streak,
      lastReadDate: streak.lastReadDate,
    );
    // A device with zero local notes but a signed-in account that has real
    // backed-up notes in Storage is exactly the "fresh install, existing
    // account" case this backup exists for -- restore them. A device that
    // already has local notes is left alone regardless of what's backed
    // up, since that's just this same session continuing normally.
    if (notes.isEmpty) {
      unawaited(_restoreFromBackupIfPossible());
    }
  }

  Future<void> _restoreFromBackupIfPossible() async {
    final uid = _authUid;
    final sync = _remoteSync;
    final repo = _repository;
    if (uid == null || sync == null || repo == null) return;

    final backedUp = await sync.listBackedUpNotes(uid);
    if (backedUp.isEmpty || !mounted) return;

    final dir = await getApplicationDocumentsDirectory();
    final restored = <Note>[];
    for (final backup in backedUp) {
      try {
        final localPath = p.join(dir.path, 'notes', '${backup.noteId}.${backup.fileExt}');
        final file = File(localPath);
        await file.create(recursive: true);
        await file.writeAsBytes(backup.fileBytes);

        final note = Note(
          id: backup.noteId,
          profileId: AppConstants.localProfileId,
          title: backup.title,
          filePath: localPath,
          fileType: backup.fileType,
          totalPages: backup.totalPages,
          colourIndex: state.notes.length + restored.length,
          uploadedAt: backup.uploadedAt,
          category: backup.category,
          courseCode: backup.courseCode,
          examYear: backup.examYear,
          storagePath: '$uid/${backup.noteId}.${backup.fileExt}',
        );
        await repo.saveNote(note);
        await repo.createPages(note.id, note.totalPages);
        restored.add(note);
      } catch (_) {
        // One corrupt restore shouldn't sink the rest -- skip and continue.
        continue;
      }
    }
    if (restored.isEmpty || !mounted) return;
    state = state.copyWith(notes: [...state.notes, ...restored]);
  }

  Future<Note> uploadNote({
    required String title,
    required String filePath,
    required NoteFileType fileType,
    required int totalPages,
    NoteCategory category = NoteCategory.note,
    String? courseCode,
    int? examYear,
  }) async {
    final note = Note(
      id: _uuid.v4(),
      profileId: AppConstants.localProfileId,
      title: title,
      filePath: filePath,
      fileType: fileType,
      totalPages: totalPages,
      colourIndex: state.notes.length,
      uploadedAt: DateTime.now(),
      category: category,
      courseCode: courseCode,
      examYear: examYear,
    );
    final repo = _repository;
    if (repo != null) {
      await repo.saveNote(note);
      await repo.createPages(note.id, totalPages);
    }
    state = state.copyWith(
      notes: [...state.notes, note],
      pagesReadByNote: {...state.pagesReadByNote, note.id: 0},
    );
    unawaited(_backupNote(note));
    return note;
  }

  /// Fire-and-forget: never blocks the upload flow, and a failure (offline,
  /// no signed-in session, etc.) is silently accepted -- the file still
  /// works fine locally either way. On success, records where it landed so
  /// a future restore knows this note is already backed up.
  Future<void> _backupNote(Note note) async {
    final sync = _remoteSync;
    final uid = _authUid;
    final repo = _repository;
    if (sync == null || uid == null || repo == null) return;
    final storagePath = await sync.backupNote(uid, note);
    if (storagePath == null || !mounted) return;
    final updated = note.copyWith(storagePath: storagePath);
    await repo.saveNote(updated);
    if (!mounted) return;
    state = state.copyWith(notes: [for (final n in state.notes) n.id == note.id ? updated : n]);
  }

  Future<void> renameNote(String id, String title) async {
    final updated = [
      for (final n in state.notes) n.id == id ? n.copyWith(title: title) : n,
    ];
    state = state.copyWith(notes: updated);
    final note = updated.firstWhere((n) => n.id == id);
    unawaited(_repository?.saveNote(note));
  }

  Future<void> touchOpened(String id) async {
    final updated = [
      for (final n in state.notes) n.id == id ? n.copyWith(lastOpenedAt: DateTime.now()) : n,
    ];
    state = state.copyWith(notes: updated);
    final note = updated.firstWhere((n) => n.id == id);
    unawaited(_repository?.saveNote(note));
  }

  Future<void> resetProgress(String id) async {
    state = state.copyWith(pagesReadByNote: {...state.pagesReadByNote, id: 0});
    await _repository?.resetProgress(id);
  }

  Future<void> deleteNote(String id) async {
    final removed = state.notes.firstWhereOrNull((n) => n.id == id);
    state = state.copyWith(
      notes: state.notes.where((n) => n.id != id).toList(),
      pagesReadByNote: {...state.pagesReadByNote}..remove(id),
    );
    await _repository?.deleteNote(id);

    final uid = _authUid;
    final sync = _remoteSync;
    if (removed?.storagePath != null && uid != null && sync != null) {
      final ext = removed!.storagePath!.split('.').last;
      unawaited(sync.deleteNoteBackup(uid, id, ext));
    }
  }

  /// Called once a page's full dwell timer completes — see
  /// `study_engine.dart#tickDwell`. Only ever fires on an unread->read
  /// transition (an already-read page is never re-timed), so the count
  /// increment here is always correct.
  Future<void> markPageRead(String noteId, int pageIndex, int dwellSeconds) async {
    final counts = {...state.pagesReadByNote};
    counts[noteId] = (counts[noteId] ?? 0) + 1;
    state = state.copyWith(pagesReadByNote: counts);
    await _repository?.markPageRead(noteId, pageIndex, dwellSeconds);
  }

  /// Logs the session and, if it cleared the day's reading threshold,
  /// extends/restarts the streak via `study_engine.dart#recordQualifyingRead`
  /// — the only place the stored streak is allowed to change.
  Future<void> logSession({
    required String noteId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int pagesRead,
    required int activeSeconds,
  }) async {
    await _repository?.logSession(ReadingSession(
      id: '',
      noteId: noteId,
      startedAt: startedAt,
      endedAt: endedAt,
      pagesRead: pagesRead,
      activeSeconds: activeSeconds,
    ));
    // The reader screen fires this from `dispose()` without awaiting it —
    // if the whole provider tree tears down before this async write lands
    // (e.g. the app itself is closing), there's no state left to update.
    if (!mounted) return;

    var next = state.copyWith(totalActiveSeconds: state.totalActiveSeconds + activeSeconds);
    if (activeSeconds ~/ 60 >= minutesRequiredForStreakDay) {
      final result = recordQualifyingRead(
        storedStreak: state.storedStreak,
        lastReadDate: state.lastReadDate,
        today: DateTime.now(),
      );
      next = next.copyWith(storedStreak: result.streak, lastReadDate: result.lastReadDate);
      await _repository?.saveStreak(streak: result.streak, lastReadDate: result.lastReadDate);
    }
    state = next;
  }
}

final notesProvider = StateNotifierProvider<NotesController, NotesState>((ref) {
  // `.select` matters here: watching `authStateProvider` directly would
  // rebuild (and so recreate) `NotesController` on every `AsyncValue`
  // transition -- including loading -> error, which is exactly what
  // happens in any test lacking a real Supabase session, and destroys an
  // in-flight `_load()` mid-flight. Selecting just the uid means this only
  // rebuilds when who's actually signed in changes.
  final authUid = ref.watch(authStateProvider.select((s) => s.valueOrNull?.userId));
  return NotesController(
    ref.watch(noteRepositoryProvider),
    remoteSync: ref.watch(noteRemoteSyncProvider),
    authUid: authUid,
  );
});

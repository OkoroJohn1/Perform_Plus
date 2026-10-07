/// Drift-backed [NoteRepository].
library;

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../local/app_database.dart';
import '../local/daos/note_dao.dart';

const _uuid = Uuid();

class DriftNoteRepository implements NoteRepository {
  final NoteDao _dao;

  DriftNoteRepository(this._dao);

  Note _fromRow(NoteRow row) => Note(
        id: row.id,
        profileId: row.profileId,
        title: row.title,
        filePath: row.filePath,
        fileType: row.fileType,
        totalPages: row.totalPages,
        colourIndex: row.colourIndex,
        uploadedAt: row.uploadedAt,
        lastOpenedAt: row.lastOpenedAt,
        category: row.category,
        courseCode: row.courseCode,
        examYear: row.examYear,
        storagePath: row.storagePath,
      );

  @override
  Future<List<Note>> loadNotes() async {
    final rows = await _dao.getAllNotes();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> saveNote(Note note) => _dao.upsertNote(
        NotesCompanion.insert(
          id: note.id,
          profileId: note.profileId,
          title: note.title,
          filePath: note.filePath,
          fileType: note.fileType,
          totalPages: note.totalPages,
          colourIndex: note.colourIndex,
          uploadedAt: note.uploadedAt,
          lastOpenedAt: Value(note.lastOpenedAt),
          category: Value(note.category),
          courseCode: Value(note.courseCode),
          examYear: Value(note.examYear),
          storagePath: Value(note.storagePath),
        ),
      );

  @override
  Future<void> deleteNote(String id) => _dao.deleteNote(id);

  @override
  Future<void> createPages(String noteId, int totalPages) => _dao.createPages([
        for (var i = 0; i < totalPages; i++)
          NotePagesCompanion.insert(noteId: noteId, pageIndex: i),
      ]);

  @override
  Future<List<NotePage>> loadPages(String noteId) async {
    final rows = await _dao.getPages(noteId);
    return rows
        .map((r) => NotePage(
              noteId: r.noteId,
              pageIndex: r.pageIndex,
              isRead: r.isRead,
              readAt: r.readAt,
              dwellSeconds: r.dwellSeconds,
            ))
        .toList();
  }

  @override
  Future<void> markPageRead(String noteId, int pageIndex, int dwellSeconds) => _dao.upsertPage(
        NotePagesCompanion.insert(
          noteId: noteId,
          pageIndex: pageIndex,
          isRead: const Value(true),
          readAt: Value(DateTime.now()),
          dwellSeconds: Value(dwellSeconds),
        ),
      );

  @override
  Future<void> resetProgress(String noteId) => _dao.resetProgress(noteId);

  @override
  Future<Map<String, int>> pagesReadCountByNote() => _dao.pagesReadCountByNote();

  @override
  Future<void> logSession(ReadingSession session) => _dao.insertSession(
        ReadingSessionsCompanion.insert(
          id: session.id.isEmpty ? _uuid.v4() : session.id,
          noteId: session.noteId,
          startedAt: session.startedAt,
          endedAt: session.endedAt,
          pagesRead: session.pagesRead,
          activeSeconds: session.activeSeconds,
        ),
      );

  @override
  Future<int> totalActiveSeconds() => _dao.totalActiveSeconds();

  @override
  Future<Map<String, int>> activeSecondsByNote() => _dao.activeSecondsByNote();

  @override
  Future<({int streak, DateTime? lastReadDate})> loadStreak() async {
    final row = await _dao.getStreak(AppConstants.localProfileId);
    return (streak: row?.currentStreak ?? 0, lastReadDate: row?.lastReadDate);
  }

  @override
  Future<void> saveStreak({required int streak, required DateTime lastReadDate}) =>
      _dao.upsertStreak(
        StudyStreaksCompanion.insert(
          profileId: AppConstants.localProfileId,
          currentStreak: Value(streak),
          lastReadDate: Value(lastReadDate),
        ),
      );
}

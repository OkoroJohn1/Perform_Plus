/// Abstract interface only — see `academic_record_repository.dart` for the
/// purity rationale.
library;

import '../models/note.dart';

abstract class NoteRepository {
  Future<List<Note>> loadNotes();
  Future<void> saveNote(Note note);
  Future<void> deleteNote(String id);

  /// Creates the note's page rows up front (all unread) so progress can
  /// always be queried as a simple count.
  Future<void> createPages(String noteId, int totalPages);
  Future<List<NotePage>> loadPages(String noteId);
  Future<void> markPageRead(String noteId, int pageIndex, int dwellSeconds);
  Future<void> resetProgress(String noteId);

  /// Read-page count per note id, in one round trip.
  Future<Map<String, int>> pagesReadCountByNote();

  Future<void> logSession(ReadingSession session);
  Future<int> totalActiveSeconds();

  /// Active reading seconds per note id, in one round trip.
  Future<Map<String, int>> activeSecondsByNote();

  Future<({int streak, DateTime? lastReadDate})> loadStreak();
  Future<void> saveStreak({required int streak, required DateTime lastReadDate});
}

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/note_pages_table.dart';
import '../tables/notes_table.dart';
import '../tables/reading_sessions_table.dart';
import '../tables/study_streak_table.dart';

part 'note_dao.g.dart';

@DriftAccessor(tables: [Notes, NotePages, ReadingSessions, StudyStreaks])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(super.db);

  Future<List<NoteRow>> getAllNotes() => select(notes).get();

  Future<NoteRow?> getNote(String id) =>
      (select(notes)..where((n) => n.id.equals(id))).getSingleOrNull();

  Future<void> upsertNote(NotesCompanion entry) => into(notes).insertOnConflictUpdate(entry);

  Future<void> deleteNote(String id) async {
    await (delete(notePages)..where((p) => p.noteId.equals(id))).go();
    await (delete(readingSessions)..where((s) => s.noteId.equals(id))).go();
    await (delete(notes)..where((n) => n.id.equals(id))).go();
  }

  Future<void> createPages(List<NotePagesCompanion> pages) =>
      batch((b) => b.insertAllOnConflictUpdate(notePages, pages));

  Future<List<NotePageRow>> getPages(String noteId) =>
      (select(notePages)
            ..where((p) => p.noteId.equals(noteId))
            ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]))
          .get();

  Future<void> upsertPage(NotePagesCompanion entry) =>
      into(notePages).insertOnConflictUpdate(entry);

  Future<void> resetProgress(String noteId) => (update(notePages)
        ..where((p) => p.noteId.equals(noteId)))
      .write(const NotePagesCompanion(isRead: Value(false), readAt: Value(null), dwellSeconds: Value(0)));

  /// Count of read pages per note, in one query — avoids an N+1 when the
  /// notes list needs every row's progress.
  Future<Map<String, int>> pagesReadCountByNote() async {
    final countExpr = notePages.noteId.count();
    final query = selectOnly(notePages)
      ..addColumns([notePages.noteId, countExpr])
      ..where(notePages.isRead.equals(true))
      ..groupBy([notePages.noteId]);
    final rows = await query.get();
    return {
      for (final row in rows) row.read(notePages.noteId)!: row.read(countExpr)!,
    };
  }

  Future<void> insertSession(ReadingSessionsCompanion entry) =>
      into(readingSessions).insert(entry);

  /// Total active reading seconds across every session, for the "Study
  /// hours" tile.
  Future<int> totalActiveSeconds() async {
    final sumExpr = readingSessions.activeSeconds.sum();
    final query = selectOnly(readingSessions)..addColumns([sumExpr]);
    final row = await query.getSingleOrNull();
    return row?.read(sumExpr) ?? 0;
  }

  /// Active reading seconds per note, in one query — the per-document half
  /// of "Study hours", shown on each note's own card.
  Future<Map<String, int>> activeSecondsByNote() async {
    final sumExpr = readingSessions.activeSeconds.sum();
    final query = selectOnly(readingSessions)
      ..addColumns([readingSessions.noteId, sumExpr])
      ..groupBy([readingSessions.noteId]);
    final rows = await query.get();
    return {
      for (final row in rows) row.read(readingSessions.noteId)!: row.read(sumExpr) ?? 0,
    };
  }

  Future<StudyStreakRow?> getStreak(String profileId) =>
      (select(studyStreaks)..where((s) => s.profileId.equals(profileId))).getSingleOrNull();

  Future<void> upsertStreak(StudyStreaksCompanion entry) =>
      into(studyStreaks).insertOnConflictUpdate(entry);
}

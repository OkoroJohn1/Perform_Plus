/// E-note domain models. Pure Dart — no Flutter, no Drift.
library;

enum NoteFileType { pdf, image }

/// Notes, past-question papers, and flashcard sets share one table and one
/// upload flow — same PDF/image handling, same reader. Past questions
/// additionally carry [Note.courseCode]/[Note.examYear] and are filterable
/// by course; they are a document library, not a quiz engine. Flashcards
/// uploaded this way are likewise a stored document a student reviews
/// themselves -- not the AI-generated, interactively-drilled deck the
/// locked "Flashcards" tile promises once a backend exists for that.
///
/// `flashcards` was added after `note`/`pastQuestion` -- Drift persists
/// this enum by index, so a new value must always be appended, never
/// inserted, or every existing stored row's category silently shifts.
enum NoteCategory { note, pastQuestion, flashcards }

/// A fixed six-colour palette, assigned by upload order (see
/// `NoteRepository.nextColourIndex`) so a note's colour stays stable across
/// reorders instead of being re-derived from something that can shift.
const noteColourPalette = <int>[0xFF5B4BD4, 0xFF16A34A, 0xFF3B82F6, 0xFFEA580C, 0xFF9333EA, 0xFF0F766E];

class Note {
  final String id;
  final String profileId;
  final String title;
  final String filePath;
  final NoteFileType fileType;
  final int totalPages;
  final int colourIndex;
  final DateTime uploadedAt;
  final DateTime? lastOpenedAt;
  final NoteCategory category;
  final String? courseCode;
  final int? examYear;

  /// Path of this note's file in Supabase Storage, once the best-effort
  /// background backup (`NoteRemoteSync`) succeeds. `null` until then, or
  /// forever on a device with no connectivity at upload time -- a failed
  /// backup never blocks or retries indefinitely; it's a durability
  /// nice-to-have, not something the reading flow depends on.
  final String? storagePath;

  const Note({
    required this.id,
    required this.profileId,
    required this.title,
    required this.filePath,
    required this.fileType,
    required this.totalPages,
    required this.colourIndex,
    required this.uploadedAt,
    this.lastOpenedAt,
    this.category = NoteCategory.note,
    this.courseCode,
    this.examYear,
    this.storagePath,
  });

  int get colour => noteColourPalette[colourIndex % noteColourPalette.length];

  Note copyWith({
    String? title,
    int? totalPages,
    int? colourIndex,
    DateTime? lastOpenedAt,
    String? courseCode,
    int? examYear,
    String? storagePath,
  }) =>
      Note(
        id: id,
        profileId: profileId,
        title: title ?? this.title,
        filePath: filePath,
        fileType: fileType,
        totalPages: totalPages ?? this.totalPages,
        colourIndex: colourIndex ?? this.colourIndex,
        uploadedAt: uploadedAt,
        lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
        category: category,
        courseCode: courseCode ?? this.courseCode,
        examYear: examYear ?? this.examYear,
        storagePath: storagePath ?? this.storagePath,
      );
}

class NotePage {
  final String noteId;
  final int pageIndex;
  final bool isRead;
  final DateTime? readAt;
  final int dwellSeconds;

  const NotePage({
    required this.noteId,
    required this.pageIndex,
    this.isRead = false,
    this.readAt,
    this.dwellSeconds = 0,
  });
}

class ReadingSession {
  final String id;
  final String noteId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int pagesRead;
  final int activeSeconds;

  const ReadingSession({
    required this.id,
    required this.noteId,
    required this.startedAt,
    required this.endedAt,
    required this.pagesRead,
    required this.activeSeconds,
  });
}

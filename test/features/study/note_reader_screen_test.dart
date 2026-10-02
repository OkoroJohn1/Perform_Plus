import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/domain/models/note.dart';
import 'package:perform_plus/domain/repositories/note_repository.dart';
import 'package:perform_plus/features/study/screens/note_reader_screen.dart';

class _FakeNoteRepository implements NoteRepository {
  final List<(String noteId, int pageIndex, int dwellSeconds)> markedRead = [];
  final List<ReadingSession> loggedSessions = [];

  @override
  Future<void> createPages(String noteId, int totalPages) async {}

  @override
  Future<void> deleteNote(String id) async {}

  final List<Note> notes;
  _FakeNoteRepository(this.notes);

  @override
  Future<List<Note>> loadNotes() async => notes;

  @override
  Future<List<NotePage>> loadPages(String noteId) async => const [];

  @override
  Future<void> logSession(ReadingSession session) async => loggedSessions.add(session);

  @override
  Future<void> markPageRead(String noteId, int pageIndex, int dwellSeconds) async =>
      markedRead.add((noteId, pageIndex, dwellSeconds));

  @override
  Future<Map<String, int>> pagesReadCountByNote() async => {};

  @override
  Future<void> resetProgress(String noteId) async {}

  @override
  Future<void> saveNote(Note note) async {}

  @override
  Future<({int streak, DateTime? lastReadDate})> loadStreak() async =>
      (streak: 0, lastReadDate: null);

  @override
  Future<void> saveStreak({required int streak, required DateTime lastReadDate}) async {}

  @override
  Future<int> totalActiveSeconds() async => 0;
}

class _FakeRenderer implements PageRenderer {
  @override
  Future<int> pageCount(String filePath) async => 3;

  @override
  Future<Uint8List?> renderPage(String filePath, int pageNumber) async => null;
}

void main() {
  testWidgets('the page dwell timer pauses when the app backgrounds and resumes on foreground',
      (tester) async {
    final now = DateTime(2026, 1, 1);
    final note = Note(
      id: 'n1',
      profileId: 'p1',
      title: 'Chapter 4',
      filePath: '/fake/chapter4.jpg',
      fileType: NoteFileType.image, // flat 12s dwell -- see study_engine.dart
      totalPages: 3,
      colourIndex: 0,
      uploadedAt: now,
    );
    // Wired to the real `NotesController` (not `.seeded()`) so that when
    // the dwell timer completes, `markPageRead` genuinely reaches the
    // repository -- `.seeded()` deliberately has no repository at all.
    final fakeRepo = _FakeNoteRepository([note]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: NoteReaderScreen(
            noteId: 'n1',
            debugRenderer: _FakeRenderer(),
            debugDisableWakelock: true,
          ),
        ),
      ),
    );
    // Not pumpAndSettle: the dwell ticker is a perpetual periodic Timer by
    // design (like a clock), so the widget tree never truly "settles".
    await tester.pump();
    await tester.pump();

    // 5 of the required 12 seconds elapse while active.
    await tester.pump(const Duration(seconds: 5));
    expect(fakeRepo.markedRead, isEmpty);

    // The app backgrounds -- the timer must stop accumulating, even though
    // 20 seconds of wall-clock time pass while it's away.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    expect(fakeRepo.markedRead, isEmpty,
        reason: 'ticks that arrive while backgrounded must not count toward the dwell');

    // Foregrounding resumes it; the remaining ~7s completes the 12s dwell
    // (padded a little to stay clear of fake-clock tick-boundary rounding).
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    expect(fakeRepo.markedRead, hasLength(1));
    expect(fakeRepo.markedRead.single.$1, 'n1');
    expect(fakeRepo.markedRead.single.$2, 0);
  });
}

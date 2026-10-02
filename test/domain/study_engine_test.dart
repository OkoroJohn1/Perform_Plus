import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/domain/engine/study_engine.dart';

void main() {
  group('streak', () {
    test('reading today extends a streak that was alive yesterday', () {
      final result = recordQualifyingRead(
        storedStreak: 4,
        lastReadDate: DateTime(2026, 1, 5),
        today: DateTime(2026, 1, 6),
      );
      expect(result.streak, 5);
    });

    test('breaks after a missed day -- effectiveStreak reads 0 without rewriting storage', () {
      // Last qualifying read was two days before "today": one full day was
      // skipped in between.
      final streak = effectiveStreak(
        storedStreak: 5,
        lastReadDate: DateTime(2026, 1, 5),
        today: DateTime(2026, 1, 8),
      );
      expect(streak, 0);
    });

    test('a new qualifying read after a gap restarts the streak at 1, not from the old count', () {
      final result = recordQualifyingRead(
        storedStreak: 5,
        lastReadDate: DateTime(2026, 1, 5),
        today: DateTime(2026, 1, 8),
      );
      expect(result.streak, 1);
    });

    test('reading again the same day is idempotent', () {
      final result = recordQualifyingRead(
        storedStreak: 3,
        lastReadDate: DateTime(2026, 1, 6),
        today: DateTime(2026, 1, 6),
      );
      expect(result.streak, 3);
    });

    test('still alive the day after the last read, before a day is actually skipped', () {
      final streak = effectiveStreak(
        storedStreak: 5,
        lastReadDate: DateTime(2026, 1, 5),
        today: DateTime(2026, 1, 6),
      );
      expect(streak, 5);
    });
  });

  group('page dwell timer', () {
    test('a page is marked read only once the full dwell has elapsed', () {
      var state = const PageDwellState(requiredSeconds: 10);

      state = tickDwell(state, 4);
      expect(state.isRead, isFalse);

      state = tickDwell(state, 5);
      expect(state.isRead, isFalse, reason: '9s elapsed of 10s required');

      state = tickDwell(state, 1);
      expect(state.isRead, isTrue, reason: '10s elapsed meets the requirement exactly');
    });

    test('ticks after the page is already read are ignored', () {
      var state = const PageDwellState(requiredSeconds: 5, elapsedSeconds: 5, isRead: true);
      state = tickDwell(state, 100);
      expect(state.elapsedSeconds, 5);
    });

    test('pausing (background/idle) stops ticks from counting toward the dwell', () {
      var state = const PageDwellState(requiredSeconds: 10);
      state = tickDwell(state, 3);
      state = pauseDwell(state);

      // Ticks that arrive while paused -- e.g. the app was backgrounded --
      // must not advance the timer, or it would measure idle time.
      state = tickDwell(state, 20);
      expect(state.elapsedSeconds, 3);
      expect(state.isRead, isFalse);

      state = resumeDwell(state);
      state = tickDwell(state, 7);
      expect(state.elapsedSeconds, 10);
      expect(state.isRead, isTrue);
    });

    test('image pages get a flat 12s regardless of word count', () {
      expect(requiredDwellSeconds(wordCount: 5000, isImagePage: true), 12);
    });

    test('text pages are floored at 8s and capped at 90s', () {
      expect(requiredDwellSeconds(wordCount: 10, isImagePage: false), 8);
      expect(requiredDwellSeconds(wordCount: 100000, isImagePage: false), 90);
    });
  });

  group('unsupported file types', () {
    test('PDF and common image extensions are accepted', () {
      expect(unsupportedFileMessage('/a/lecture.pdf'), isNull);
      expect(unsupportedFileMessage('/a/scan.jpg'), isNull);
      expect(unsupportedFileMessage('/a/scan.PNG'), isNull);
    });

    test('a PowerPoint file is rejected with a concrete, actionable message', () {
      final message = unsupportedFileMessage('/a/lecture 4.pptx');
      expect(message, "We can't open .pptx files yet. Export it as a PDF and try again.");
    });

    test('a Word document is rejected the same way', () {
      final message = unsupportedFileMessage('/a/handout.docx');
      expect(message, "We can't open .docx files yet. Export it as a PDF and try again.");
    });
  });

  group('progress percentage', () {
    test('matches pagesRead over totalPages exactly', () {
      expect(progressFraction(pagesRead: 6, totalPages: 24), 0.25);
      expect(progressFraction(pagesRead: 24, totalPages: 24), 1.0);
      expect(progressFraction(pagesRead: 0, totalPages: 24), 0.0);
    });

    test('never exceeds 1.0 even if pagesRead somehow overshoots', () {
      expect(progressFraction(pagesRead: 30, totalPages: 24), 1.0);
    });

    test('a note with no pages reads as 0, not a division error', () {
      expect(progressFraction(pagesRead: 0, totalPages: 0), 0.0);
    });
  });
}

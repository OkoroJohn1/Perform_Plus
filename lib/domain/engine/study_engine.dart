/// Pure Study-tab calculations — no Flutter, no I/O. Mirrors
/// `cgpa_engine.dart`'s purity contract: every number the reader/streak UI
/// shows should trace back to a function in this file, not be computed
/// inline in a widget.
library;

import 'dart:math';

/// Shown for 6 seconds every time a document is opened (see
/// `study_advice_reveal_screen.dart`) — a deliberate pause before reading
/// starts, not a one-time tip. A fixed list rather than anything generated:
/// these are honest, specific, and never invented per-session.
const studyAdviceMessages = [
  'Reading a page and remembering it are two different things. Pause and ask yourself what you just read.',
  "The timer only knows the app is open. Whether you're actually studying is still entirely up to you.",
  'Put your phone where you can’t reach it for the next few minutes. Notifications are the easiest way to lose focus.',
  'Try explaining this page out loud, like you’re teaching it to someone else. If you can’t, read it again.',
  'A tired brain doesn’t absorb much. If you’re exhausted, a short break now beats an hour of staring blankly.',
  "Skimming feels like progress. It usually isn't. Slow down on the parts that don't make sense yet.",
  'Write down one question this page raises for you. Looking for the answer is how it actually sticks.',
  'Your future self is the one who inherits whatever you do with this time right now.',
  'Studying tired, distracted, or half-present only gives you the feeling of having studied.',
  "No one is grading how long this document stayed open — only what you actually take from it.",
];

String randomStudyAdvice([Random? random]) {
  final rng = random ?? Random();
  return studyAdviceMessages[rng.nextInt(studyAdviceMessages.length)];
}

/// How long the pre-reading advice screen stays up before auto-advancing
/// into the document.
const studyAdviceRevealSeconds = 6;

/// Minimum time a page must stay open before it counts as read. 200 words
/// per minute is a conservative reading speed; the 90s cap stops a dense
/// page from becoming a punishment, and the 8s floor stops a near-empty
/// page from counting instantly. Image pages have no extractable text, so
/// they get a flat, honest 12 seconds instead of running through the
/// word-count formula.
int requiredDwellSeconds({required int? wordCount, required bool isImagePage}) {
  if (isImagePage) return 12;
  final words = wordCount ?? 0;
  final computed = (words / 200) * 60;
  final floored = computed < 8 ? 8.0 : computed;
  final capped = floored > 90 ? 90.0 : floored;
  return capped.round();
}

/// How far through a note the student is, 0.0-1.0. `totalPages <= 0` reads
/// as 0 rather than dividing by zero or reporting a nonsensical negative.
double progressFraction({required int pagesRead, required int totalPages}) {
  if (totalPages <= 0) return 0.0;
  final fraction = pagesRead / totalPages;
  return fraction.clamp(0.0, 1.0);
}

/// File types the reader can actually open in V1 — DOCX/PPTX need
/// server-side conversion (no backend yet), so they're rejected with a
/// concrete message rather than failing silently.
const supportedNoteExtensions = {'pdf', 'png', 'jpg', 'jpeg'};

/// Null when [filePath]'s extension is supported; otherwise the exact
/// message to show the student.
String? unsupportedFileMessage(String filePath) {
  final dot = filePath.lastIndexOf('.');
  final ext = dot == -1 ? '' : filePath.substring(dot + 1).toLowerCase();
  if (supportedNoteExtensions.contains(ext)) return null;
  return "We can't open .$ext files yet. Export it as a PDF and try again.";
}

/// The streak value to show/act on "as of" [today], given what was stored
/// after the last qualifying read. Storage never changes just because time
/// passed — see [recordQualifyingRead] for the only place the streak
/// actually updates — so a missed day is detected here, at read time, by
/// comparing dates, never inferred from session timestamps.
int effectiveStreak({
  required int storedStreak,
  required DateTime? lastReadDate,
  required DateTime today,
}) {
  if (lastReadDate == null) return 0;
  final last = DateTime(lastReadDate.year, lastReadDate.month, lastReadDate.day);
  final now = DateTime(today.year, today.month, today.day);
  final daysSince = now.difference(last).inDays;
  // 0 = read today already; 1 = read yesterday, still alive today.
  return daysSince <= 1 ? storedStreak : 0;
}

/// New (streak, lastReadDate) to persist when at least 10 minutes of
/// reading is logged on [today] — the one place the streak is allowed to
/// change. Consecutive calendar days extend it; a gap of more than one day
/// restarts it at 1; the same day is idempotent.
({int streak, DateTime lastReadDate}) recordQualifyingRead({
  required int storedStreak,
  required DateTime? lastReadDate,
  required DateTime today,
}) {
  final now = DateTime(today.year, today.month, today.day);
  if (lastReadDate == null) return (streak: 1, lastReadDate: now);

  final last = DateTime(lastReadDate.year, lastReadDate.month, lastReadDate.day);
  final daysSince = now.difference(last).inDays;
  if (daysSince == 0) return (streak: storedStreak, lastReadDate: now);
  if (daysSince == 1) return (streak: storedStreak + 1, lastReadDate: now);
  return (streak: 1, lastReadDate: now);
}

/// A day counts toward the streak once a SINGLE document session (open to
/// exit, active time only — see `ReadingSessionRow.activeSeconds`) reaches
/// this many minutes. Deliberately not an aggregate across several short
/// sessions: opening three different notes for ten minutes each proves far
/// less sustained focus than thirty continuous minutes on one.
const minutesRequiredForStreakDay = 30;

/// One page's dwell-timer state — see [tickDwell]/[pauseDwell]/[resumeDwell].
/// Deliberately separate from any widget/Timer: the reader screen drives
/// this with a real periodic timer and platform lifecycle callbacks, but
/// the state machine itself takes plain integer seconds so it can be
/// tested without waiting on real time.
class PageDwellState {
  final int requiredSeconds;
  final int elapsedSeconds;
  final bool isPaused;
  final bool isRead;

  const PageDwellState({
    required this.requiredSeconds,
    this.elapsedSeconds = 0,
    this.isPaused = false,
    this.isRead = false,
  });

  double get progress =>
      requiredSeconds <= 0 ? 1.0 : (elapsedSeconds / requiredSeconds).clamp(0.0, 1.0);

  PageDwellState copyWith({int? elapsedSeconds, bool? isPaused, bool? isRead}) => PageDwellState(
        requiredSeconds: requiredSeconds,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        isPaused: isPaused ?? this.isPaused,
        isRead: isRead ?? this.isRead,
      );
}

/// Advances the dwell timer by [seconds] of genuinely active time. A no-op
/// while paused or already read — ticks that arrive after the page is
/// marked read, or while backgrounded/idle, must never count, or the timer
/// would measure idle time instead of reading.
PageDwellState tickDwell(PageDwellState state, int seconds) {
  if (state.isPaused || state.isRead) return state;
  final elapsed = state.elapsedSeconds + seconds;
  return state.copyWith(elapsedSeconds: elapsed, isRead: elapsed >= state.requiredSeconds);
}

PageDwellState pauseDwell(PageDwellState state) =>
    state.isRead ? state : state.copyWith(isPaused: true);

PageDwellState resumeDwell(PageDwellState state) =>
    state.isRead ? state : state.copyWith(isPaused: false);

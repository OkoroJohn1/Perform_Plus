/// A single slip photo kept after being run through extraction -- the
/// "Result slip wallet" on the Results screen. Pure Dart, no Flutter/Drift
/// imports (see `academic_record_repository.dart`'s doc comment for why
/// `lib/domain/` stays pure).
///
/// Local-only for now, like notes/photos were before their own remote-sync
/// pass landed -- a slip lost to an uninstall is a smaller loss than losing
/// the semester results it was used to produce, which already are backed
/// up. Follow-up work if this needs the same Supabase Storage backup.
library;

enum SlipKind {
  /// A course-registration slip, run through the server-side
  /// `extract-course-slip` vision model (`course_slip_extraction_service.dart`).
  registration,

  /// An issued result slip (has grades), run through the on-device ML Kit
  /// recognizer (`result_slip_ocr_service.dart`).
  result,
}

class SlipUpload {
  final String id;
  final String profileId;
  final SlipKind kind;

  /// Path to the saved JPEG copy on disk (see `slip_wallet_store.dart`) --
  /// never the picker's own temp path, which the OS can reclaim at any time.
  final String filePath;

  /// How many course rows extraction found on it, or null if extraction
  /// never completed (offline/unreadable) -- the slip is still kept either
  /// way, since "I uploaded this" doesn't require "and it worked."
  final int? extractedCourseCount;

  final DateTime capturedAt;

  const SlipUpload({
    required this.id,
    required this.profileId,
    required this.kind,
    required this.filePath,
    required this.extractedCourseCount,
    required this.capturedAt,
  });
}

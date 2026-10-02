/// Abstract interface only — no `package:flutter`, `package:flutter_riverpod`
/// or `package:drift` imports. `dart:async` (core Dart) is fine: a
/// repository interface describing I/O-backed operations needs `Future`
/// return types to be meaningful at all.
///
/// `lib/data/repositories/drift_academic_record_repository.dart` implements
/// this today. A future remote-sync implementation can satisfy the same
/// contract without any UI or provider changes.
library;

import '../models/course_result.dart';

abstract class AcademicRecordRepository {
  Future<List<Semester>> loadSemesters();
  Future<void> addSemester(Semester semester);
  Future<void> updateSemester(Semester semester);
  Future<void> removeSemester(String id);

  /// Re-keys every semester currently stored under [fromProfileId] to
  /// [toProfileId] — the sign-up handoff from the pre-auth placeholder
  /// profile to the real Supabase auth uid. A no-op (matches zero rows)
  /// when there is nothing to reassign, so it is safe to call on every
  /// successful auth resolution, not just a fresh sign-up.
  Future<void> reassignProfile(String fromProfileId, String toProfileId);

  /// Whether [profileId] already has at least one semester in local
  /// storage. Checked before [reassignProfile] so a returning user who
  /// already has real data on this device doesn't get a leftover pre-auth
  /// draft silently merged in as duplicates — see [discardProfile].
  Future<bool> hasSemestersForProfile(String profileId);

  /// Deletes every semester (and its course results) currently stored
  /// under [profileId]. The counterpart to [reassignProfile]: used instead
  /// of it when [hasSemestersForProfile] is already true for the real
  /// account, since in that case the pre-auth draft is almost certainly a
  /// mistaken repeat of onboarding rather than legitimate new data.
  Future<void> discardProfile(String profileId);
}

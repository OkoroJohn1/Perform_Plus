/// Abstract interface only — see `academic_record_repository.dart` for the
/// purity rationale.
library;

import '../models/grading_scheme.dart';

abstract class GradingSchemeRepository {
  /// The scheme currently used to compute the local profile's whole
  /// academic record — null if none has been saved yet.
  Future<GradingScheme?> loadActiveScheme();

  /// Snapshots [scheme] into storage and marks it as active. Always
  /// upserts both the scheme row and the active-scheme pointer — never
  /// assumes either already exists.
  Future<void> saveActiveScheme(GradingScheme scheme);
}

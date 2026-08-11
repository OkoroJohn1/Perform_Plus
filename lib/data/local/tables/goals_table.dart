import 'package:drift/drift.dart';

/// Singleton row, always keyed by `AppConstants.localProfileId`.
/// `ClassificationBand` is flattened into columns rather than JSON-encoded —
/// it's 4 scalars, and flattening avoids a converter that only this table
/// would ever use.
class Goals extends Table {
  TextColumn get profileId => text()();
  TextColumn get bandLabel => text()();
  TextColumn get bandShortLabel => text()();
  RealColumn get bandMinCgpa => real()();
  RealColumn get bandMaxCgpa => real()();
  IntColumn get semestersRemaining => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {profileId};
}

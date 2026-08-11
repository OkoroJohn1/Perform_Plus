import 'package:drift/drift.dart';

/// Singleton row, always keyed by `AppConstants.localProfileId` — there is
/// no multi-user auth yet. `activeSchemeId` tracks which grading scheme
/// (see `GradingSchemes`) the whole academic record is currently computed
/// against, matching `AcademicRecord.scheme` being a single field today.
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get regNumber => text()();
  TextColumn get department => text()();
  IntColumn get currentLevel => integer()();
  IntColumn get entryYear => integer()();
  IntColumn get expectedGraduationYear => integer()();
  TextColumn get activeSchemeId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

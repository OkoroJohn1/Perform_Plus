import 'package:drift/drift.dart';

/// A generic key-value store for small device-local preferences that
/// don't warrant their own table -- today just the chosen theme mode
/// (`Appearance` on the settings screen). Not synced, not tied to a
/// profile: these are per-installation, not per-account.
class LocalSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

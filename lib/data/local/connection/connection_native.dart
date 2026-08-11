/// Native (Android/iOS/desktop) drift connection — FFI-backed SQLite file
/// in the app's documents directory. Only ever imported on platforms with
/// `dart:io`; see the conditional import in `app_database.dart`.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor connect() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'perform_plus.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

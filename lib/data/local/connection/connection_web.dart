/// Web drift connection — WebAssembly SQLite via `sqlite3.wasm` and the
/// drift worker, both already checked into `web/`. Only ever imported on
/// web builds; see the conditional import in `app_database.dart`.
library;

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor connect() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'perform_plus',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}

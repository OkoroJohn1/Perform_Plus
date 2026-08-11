/// Fallback for platforms with neither `dart:io` nor `dart:js_interop` —
/// selected by the conditional import in `app_database.dart` when neither
/// the native nor the web branch applies. Should never actually run.
library;

import 'package:drift/drift.dart';

QueryExecutor connect() {
  throw UnsupportedError(
    'This platform has no drift connection implementation.',
  );
}

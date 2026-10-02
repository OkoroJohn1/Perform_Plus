import 'dart:convert';

import 'package:drift/drift.dart';

/// JSON-encodes a `Map<String, String>` into a single TEXT column — used
/// for `Notifications.payload` (routing/presentation metadata that doesn't
/// warrant its own column per entry).
class StringMapConverter extends TypeConverter<Map<String, String>, String> {
  const StringMapConverter();

  @override
  Map<String, String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as Map).cast<String, String>();

  @override
  String toSql(Map<String, String> value) => jsonEncode(value);
}

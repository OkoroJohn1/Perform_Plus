import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/models/grading_scheme.dart';

/// JSON-encodes a scheme's grade list into a single TEXT column, through
/// the model's own `toJson`/`fromJson` — grades are always read/written as
/// a whole list, never queried individually, so a converter is simpler
/// than a separate table.
class GradeDefinitionListConverter
    extends TypeConverter<List<GradeDefinition>, String> {
  const GradeDefinitionListConverter();

  @override
  List<GradeDefinition> fromSql(String fromDb) => (jsonDecode(fromDb) as List)
      .map((e) => GradeDefinition.fromJson(e as Map<String, dynamic>))
      .toList();

  @override
  String toSql(List<GradeDefinition> value) =>
      jsonEncode(value.map((g) => g.toJson()).toList());
}

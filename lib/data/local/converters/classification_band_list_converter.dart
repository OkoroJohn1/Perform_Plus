import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/models/grading_scheme.dart';

/// JSON-encodes a scheme's classification bands into a single TEXT column —
/// same rationale as [GradeDefinitionListConverter].
class ClassificationBandListConverter
    extends TypeConverter<List<ClassificationBand>, String> {
  const ClassificationBandListConverter();

  @override
  List<ClassificationBand> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List)
          .map((e) => ClassificationBand.fromJson(e as Map<String, dynamic>))
          .toList();

  @override
  String toSql(List<ClassificationBand> value) =>
      jsonEncode(value.map((b) => b.toJson()).toList());
}

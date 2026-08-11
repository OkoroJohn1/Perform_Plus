import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/grading_schemes_table.dart';

part 'grading_scheme_dao.g.dart';

@DriftAccessor(tables: [GradingSchemes])
class GradingSchemeDao extends DatabaseAccessor<AppDatabase>
    with _$GradingSchemeDaoMixin {
  GradingSchemeDao(super.db);

  Future<GradingSchemeRow?> getById(String id) =>
      (select(gradingSchemes)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<void> upsertScheme(GradingSchemesCompanion entry) =>
      into(gradingSchemes).insertOnConflictUpdate(entry);
}

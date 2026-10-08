import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/slip_uploads_table.dart';

part 'slip_upload_dao.g.dart';

@DriftAccessor(tables: [SlipUploads])
class SlipUploadDao extends DatabaseAccessor<AppDatabase> with _$SlipUploadDaoMixin {
  SlipUploadDao(super.db);

  /// Newest first -- a wallet is browsed most-recent-upload-first.
  Future<List<SlipUploadRow>> getAllUploads() =>
      (select(slipUploads)..orderBy([(u) => OrderingTerm.desc(u.capturedAt)])).get();

  Future<void> insertUpload(SlipUploadsCompanion entry) => into(slipUploads).insert(entry);

  Future<void> deleteUpload(String id) => (delete(slipUploads)..where((u) => u.id.equals(id))).go();

  Future<void> deleteAllForProfile(String profileId) =>
      (delete(slipUploads)..where((u) => u.profileId.equals(profileId))).go();
}

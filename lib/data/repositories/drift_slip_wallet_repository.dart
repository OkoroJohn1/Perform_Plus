import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/slip_upload.dart';
import '../../domain/repositories/slip_wallet_repository.dart';
import '../local/app_database.dart';
import '../local/daos/slip_upload_dao.dart';

class DriftSlipWalletRepository implements SlipWalletRepository {
  final SlipUploadDao _dao;

  DriftSlipWalletRepository(this._dao);

  @override
  Future<List<SlipUpload>> loadAll() async {
    final rows = await _dao.getAllUploads();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> add(SlipUpload upload) => _dao.insertUpload(
        SlipUploadsCompanion.insert(
          id: upload.id,
          profileId: AppConstants.localProfileId,
          kind: upload.kind.name,
          filePath: upload.filePath,
          extractedCourseCount: Value(upload.extractedCourseCount),
          capturedAt: upload.capturedAt,
        ),
      );

  @override
  Future<void> remove(String id) => _dao.deleteUpload(id);

  SlipUpload _toDomain(SlipUploadRow row) => SlipUpload(
        id: row.id,
        profileId: row.profileId,
        kind: SlipKind.values.firstWhere((k) => k.name == row.kind, orElse: () => SlipKind.registration),
        filePath: row.filePath,
        extractedCourseCount: row.extractedCourseCount,
        capturedAt: row.capturedAt,
      );
}

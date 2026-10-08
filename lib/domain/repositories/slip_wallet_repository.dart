/// Abstract interface only — see `academic_record_repository.dart`'s doc
/// comment for why (`lib/domain/` stays pure, no Flutter/Drift imports).
library;

import '../models/slip_upload.dart';

abstract class SlipWalletRepository {
  Future<List<SlipUpload>> loadAll();

  Future<void> add(SlipUpload upload);

  Future<void> remove(String id);
}

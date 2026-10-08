/// On-disk storage for the Result slip wallet -- unlike the single profile
/// photo (`profile_photo_store.dart`, always one fixed filename), there can
/// be many slips, so each gets its own uuid-named file under a dedicated
/// subdirectory rather than overwriting a shared path.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<Directory> _walletDir() async {
  final dir = await getApplicationDocumentsDirectory();
  final walletDir = Directory(p.join(dir.path, 'slip_wallet'));
  if (!await walletDir.exists()) await walletDir.create(recursive: true);
  return walletDir;
}

/// Saves [bytes] under [id] and returns the saved file's path. Callers pass
/// whatever bytes they already have in hand at the point of extraction --
/// already-downscaled JPEG for a registration slip, the raw picked photo
/// for a result slip (see `result_slip_ocr_service.dart`'s doc comment on
/// why that one is never downscaled).
Future<String> saveSlipToWallet({required String id, required List<int> bytes}) async {
  final dir = await _walletDir();
  final file = File(p.join(dir.path, '$id.jpg'));
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<void> deleteSlipFromWallet(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {
    // Best-effort -- a stray file left on disk isn't worth surfacing.
  }
}

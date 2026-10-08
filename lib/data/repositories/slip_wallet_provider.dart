/// Result slip wallet state -- every slip photo (registration or result)
/// that was run through extraction, kept for the student to look back at
/// from the Results screen. Local-only, loaded once from Drift then kept
/// in memory, same pattern as [CalendarMarksController].
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/slip_upload.dart';
import '../../domain/repositories/slip_wallet_repository.dart';
import '../local/slip_wallet_store.dart';
import 'repository_providers.dart';

const _uuid = Uuid();

class SlipWalletController extends StateNotifier<List<SlipUpload>> {
  final SlipWalletRepository? _repository;

  SlipWalletController(this._repository) : super(const []) {
    unawaited(_load());
  }

  SlipWalletController.seeded(List<SlipUpload> uploads)
      : _repository = null,
        super(uploads);

  Future<void> _load() async {
    final repo = _repository;
    if (repo == null) return;
    state = await repo.loadAll();
  }

  /// Saves [bytes] as a new wallet entry and returns it. [extractedCourseCount]
  /// is best supplied once extraction finishes, but a slip is kept even when
  /// extraction fails or the device is offline -- "I uploaded this" doesn't
  /// require "and it worked."
  Future<SlipUpload> add({
    required List<int> bytes,
    required SlipKind kind,
    int? extractedCourseCount,
  }) async {
    final id = _uuid.v4();
    final path = await saveSlipToWallet(id: id, bytes: bytes);
    final upload = SlipUpload(
      id: id,
      profileId: '',
      kind: kind,
      filePath: path,
      extractedCourseCount: extractedCourseCount,
      capturedAt: DateTime.now(),
    );
    await _repository?.add(upload);
    state = [upload, ...state];
    return upload;
  }

  Future<void> remove(SlipUpload upload) async {
    await _repository?.remove(upload.id);
    await deleteSlipFromWallet(upload.filePath);
    state = state.where((u) => u.id != upload.id).toList();
  }
}

final slipWalletProvider = StateNotifierProvider<SlipWalletController, List<SlipUpload>>(
  (ref) => SlipWalletController(ref.watch(slipWalletRepositoryProvider)),
);

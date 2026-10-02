/// Persists where the student last dragged the Performia chat button to
/// (`AdvisorFab`, made freely movable per request) -- stored as a fraction
/// of the screen (0.0-1.0 on each axis, not raw pixels) so it still lands
/// somewhere sane after a rotation or on a different device size. `null`
/// means "never moved yet", which `app_scaffold.dart` resolves to its own
/// default corner rather than this provider guessing a screen size it
/// doesn't have.
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/daos/local_settings_dao.dart';
import '../../data/repositories/repository_providers.dart';

const _advisorFabPositionKey = 'advisorFabPositionFraction';

class AdvisorFabPositionController extends StateNotifier<Offset?> {
  final LocalSettingsDao? _dao;

  AdvisorFabPositionController(this._dao) : super(null) {
    unawaited(_load());
  }

  Future<void> _load() async {
    final stored = await _dao?.get(_advisorFabPositionKey);
    if (stored == null) return;
    final parts = stored.split(',');
    if (parts.length != 2) return;
    final dx = double.tryParse(parts[0]);
    final dy = double.tryParse(parts[1]);
    if (dx == null || dy == null) return;
    state = Offset(dx, dy);
  }

  Future<void> setFraction(Offset fraction) async {
    state = fraction;
    await _dao?.set(_advisorFabPositionKey, '${fraction.dx},${fraction.dy}');
  }
}

final advisorFabPositionProvider =
    StateNotifierProvider<AdvisorFabPositionController, Offset?>(
  (ref) => AdvisorFabPositionController(ref.watch(localSettingsDaoProvider)),
);

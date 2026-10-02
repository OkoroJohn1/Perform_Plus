/// App-lock PIN state. The salt+hash pair lives in secure storage (Android
/// Keystore/iOS Keychain-backed) — never local_settings/Drift, since that's
/// plain SQLite on disk. `promptDismissed` is not sensitive and lives in
/// local_settings instead, matching every other lightweight app preference.
///
/// [unlocked] is deliberately in-memory only, defaulting to `false`
/// whenever a PIN is set — a fresh cold start always requires re-entry.
/// Backgrounding does NOT re-lock immediately any more: [handlePause]/
/// [handleResume] (called by `app.dart`'s lifecycle observer) only re-lock
/// once the app has actually been in the background for [autoLockMinutes]
/// or longer, so a brief trip to the system camera/share sheet/picker
/// (see `profile_setup_screen.dart`'s photo flow, which used to lose its
/// in-flight picture to an instant re-lock) doesn't force a PIN re-entry
/// the moment control returns.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/repository_providers.dart';
import '../services/biometric_service.dart';
import '../services/pin_service.dart';
import 'auth_provider.dart';

const _pinSaltKey = 'perform_plus.pin_salt';
const _pinHashKey = 'perform_plus.pin_hash';
const _pinPromptDismissedKey = 'pinPromptDismissed';
const _biometricEnabledKey = 'pinBiometricEnabled';
const _autoLockMinutesKey = 'pinAutoLockMinutes';
const defaultAutoLockMinutes = 1;

class PinState {
  final bool isSet;
  final bool unlocked;
  final bool promptDismissed;
  final bool loaded;

  /// Whether THIS device can even show a biometric prompt (hardware +
  /// something enrolled) — checked once at load, independent of whether
  /// the student has actually turned the toggle on.
  final bool biometricAvailable;

  /// Whether the student opted in to fingerprint/face unlock alongside the
  /// PIN. Meaningless (and never actioned) unless [isSet] is also true —
  /// biometrics unlock the PIN gate, they never replace having a PIN.
  final bool biometricEnabled;

  /// How long the app can sit backgrounded before the next resume re-locks
  /// it -- 1 to 60 minutes, student-configurable, defaulting to
  /// [defaultAutoLockMinutes]. See [PinController.handlePause]/[handleResume].
  final int autoLockMinutes;

  const PinState({
    this.isSet = false,
    this.unlocked = false,
    this.promptDismissed = false,
    this.loaded = false,
    this.biometricAvailable = false,
    this.biometricEnabled = false,
    this.autoLockMinutes = defaultAutoLockMinutes,
  });

  /// Whether a lock screen should currently be shown in front of the app.
  bool get shouldLock => isSet && !unlocked;

  /// Whether the lock screen should offer the fingerprint/face shortcut.
  bool get canUseBiometrics => isSet && biometricAvailable && biometricEnabled;

  PinState copyWith({
    bool? isSet,
    bool? unlocked,
    bool? promptDismissed,
    bool? loaded,
    bool? biometricAvailable,
    bool? biometricEnabled,
    int? autoLockMinutes,
  }) =>
      PinState(
        isSet: isSet ?? this.isSet,
        unlocked: unlocked ?? this.unlocked,
        promptDismissed: promptDismissed ?? this.promptDismissed,
        loaded: loaded ?? this.loaded,
        biometricAvailable: biometricAvailable ?? this.biometricAvailable,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      );
}

class PinController extends StateNotifier<PinState> {
  final Ref _ref;
  final BiometricService _biometrics;

  /// When the app was last backgrounded -- in-memory only, cleared on the
  /// matching resume. `null` means "not currently backgrounded" (or a PIN
  /// isn't set, in which case this is never populated at all).
  DateTime? _pausedAt;

  PinController(this._ref, [BiometricService? biometrics])
      : _biometrics = biometrics ?? BiometricService(),
        super(const PinState()) {
    unawaited(_load());
  }

  Future<void> _load() async {
    final storage = _ref.read(secureStorageProvider);
    final salt = await storage.read(key: _pinSaltKey);
    final hash = await storage.read(key: _pinHashKey);
    final dao = _ref.read(localSettingsDaoProvider);
    final dismissed = await dao.get(_pinPromptDismissedKey);
    final biometricEnabled = await dao.get(_biometricEnabledKey);
    final biometricAvailable = await _biometrics.isAvailable();
    final storedAutoLockMinutes = int.tryParse(await dao.get(_autoLockMinutesKey) ?? '');
    state = state.copyWith(
      isSet: salt != null && hash != null,
      promptDismissed: dismissed == 'true',
      loaded: true,
      biometricAvailable: biometricAvailable,
      biometricEnabled: biometricEnabled == 'true',
      autoLockMinutes: storedAutoLockMinutes?.clamp(1, 60) ?? defaultAutoLockMinutes,
    );
  }

  Future<void> setPin(String pin) async {
    final hashed = hashPin(pin);
    final storage = _ref.read(secureStorageProvider);
    await storage.write(key: _pinSaltKey, value: hashed.salt);
    await storage.write(key: _pinHashKey, value: hashed.hash);
    state = state.copyWith(isSet: true, unlocked: true);
  }

  Future<bool> verify(String pin) async {
    final storage = _ref.read(secureStorageProvider);
    final salt = await storage.read(key: _pinSaltKey);
    final hash = await storage.read(key: _pinHashKey);
    if (salt == null || hash == null) return false;
    final matches = verifyPin(pin, PinHash(salt: salt, hash: hash));
    if (matches) state = state.copyWith(unlocked: true);
    return matches;
  }

  /// Shows the system fingerprint/face prompt and unlocks on success. A
  /// no-op returning false if biometric unlock isn't currently offered
  /// ([PinState.canUseBiometrics]) — callers always keep the PIN pad as
  /// the fallback regardless of this result.
  Future<bool> unlockWithBiometrics() async {
    if (!state.canUseBiometrics) return false;
    final ok = await _biometrics.authenticate();
    if (ok) state = state.copyWith(unlocked: true);
    return ok;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    state = state.copyWith(biometricEnabled: enabled);
    await _ref.read(localSettingsDaoProvider).set(_biometricEnabledKey, enabled.toString());
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    final clamped = minutes.clamp(1, 60);
    state = state.copyWith(autoLockMinutes: clamped);
    await _ref.read(localSettingsDaoProvider).set(_autoLockMinutesKey, clamped.toString());
  }

  Future<void> clearPin() async {
    final storage = _ref.read(secureStorageProvider);
    await storage.delete(key: _pinSaltKey);
    await storage.delete(key: _pinHashKey);
    state = state.copyWith(isSet: false, unlocked: false);
    // Biometrics unlock the PIN gate -- once there's no PIN, there's
    // nothing left for them to unlock.
    await setBiometricEnabled(false);
  }

  /// Called by `app.dart`'s `WidgetsBindingObserver` when the app is
  /// backgrounded. Doesn't lock immediately -- just remembers when, so
  /// [handleResume] can compare against [PinState.autoLockMinutes].
  void handlePause() {
    if (state.isSet) _pausedAt = DateTime.now();
  }

  /// Called on every resume. Re-locks only if the background lasted at
  /// least [PinState.autoLockMinutes] -- a resume that follows a pause too
  /// recent to count (e.g. the system camera/share sheet/file picker
  /// returning control) leaves the session unlocked.
  void handleResume() {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null || !state.isSet) return;
    if (DateTime.now().difference(pausedAt) >= Duration(minutes: state.autoLockMinutes)) {
      state = state.copyWith(unlocked: false);
    }
  }

  Future<void> dismissPrompt() async {
    state = state.copyWith(promptDismissed: true);
    await _ref.read(localSettingsDaoProvider).set(_pinPromptDismissedKey, 'true');
  }
}

final pinProvider = StateNotifierProvider<PinController, PinState>((ref) => PinController(ref));

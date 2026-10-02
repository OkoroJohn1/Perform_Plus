/// Thin wrapper around `local_auth` — pure device-capability/prompt calls,
/// no storage or Riverpod state here (that's `pin_provider.dart`, which
/// decides *whether* biometric unlock is currently enabled). Kept separate
/// so the PIN provider stays testable without a real platform channel.
library;

import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth;

  BiometricService([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  /// Whether this device has enrolled biometrics (fingerprint/face) AND the
  /// platform supports the prompt at all -- both checks are needed since a
  /// device can support the API but have nothing enrolled yet.
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system fingerprint/face prompt. Returns false on any failure
  /// (no biometrics enrolled, user cancelled, lockout, missing hardware) --
  /// callers fall back to the PIN pad, which is always available.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Perform+',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}

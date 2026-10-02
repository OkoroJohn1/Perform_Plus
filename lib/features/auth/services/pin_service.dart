/// App-lock PIN hashing — pure Dart, no storage/UI concerns here (that's
/// `pin_provider.dart`). The PIN itself is never stored or compared in
/// plaintext: a random salt is generated once at set-time and stored
/// alongside a SHA-256 hash of `salt + pin`, so two devices setting the
/// same 4-digit PIN never produce the same stored value and a leaked
/// storage blob can't be reversed to the PIN directly.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const pinLength = 4;

class PinHash {
  final String salt;
  final String hash;

  const PinHash({required this.salt, required this.hash});
}

String _randomSalt() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return base64Url.encode(bytes);
}

String _hashWithSalt(String pin, String salt) =>
    sha256.convert(utf8.encode('$salt:$pin')).toString();

PinHash hashPin(String pin) {
  final salt = _randomSalt();
  return PinHash(salt: salt, hash: _hashWithSalt(pin, salt));
}

bool verifyPin(String pin, PinHash stored) => _hashWithSalt(pin, stored.salt) == stored.hash;

bool isValidPinFormat(String pin) => pin.length == pinLength && RegExp(r'^\d+$').hasMatch(pin);

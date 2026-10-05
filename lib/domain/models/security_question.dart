/// Security-question PIN recovery — pure Dart, no I/O. Mirrors
/// `pin_service.dart`'s hashing approach exactly: a random salt generated
/// once, SHA-256 of `salt:normalizedAnswer`, never the plaintext answer
/// stored or compared directly. Answers are normalised (trimmed, lower-
/// cased) before hashing so "Lagos" and "lagos " verify identically — a
/// student should not fail recovery over capitalisation they don't
/// remember precisely.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// A fixed bank a student picks three DISTINCT questions from during setup
/// — free-text questions would be harder to recover consistently (a typo
/// in the question itself locks a student out of ever matching it again).
const securityQuestionBank = <String>[
  "What was the name of your first primary school?",
  "What is your mother's maiden name?",
  "What was the name of your first pet?",
  "What city were you born in?",
  "What was your favourite subject in secondary school?",
  "What is the name of your best childhood friend?",
  "What was the make of your family's first car?",
  "What street did you grow up on?",
];

const securityQuestionCount = 3;

class SecurityAnswerHash {
  final String salt;
  final List<String> questions;
  final List<String> answerHashes;

  const SecurityAnswerHash({
    required this.salt,
    required this.questions,
    required this.answerHashes,
  });
}

String _normalize(String answer) => answer.trim().toLowerCase();

String _randomSalt() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return base64Url.encode(bytes);
}

String _hashAnswer(String answer, String salt) =>
    sha256.convert(utf8.encode('$salt:${_normalize(answer)}')).toString();

/// Hashes a fresh set of question/answer pairs at setup time — one new
/// random salt shared across all three, matching the PIN's own one-salt
/// model.
SecurityAnswerHash hashAnswers(List<String> questions, List<String> answers) {
  assert(questions.length == securityQuestionCount);
  assert(answers.length == securityQuestionCount);
  final salt = _randomSalt();
  return SecurityAnswerHash(
    salt: salt,
    questions: questions,
    answerHashes: [for (final a in answers) _hashAnswer(a, salt)],
  );
}

/// Verifies a student's recovery attempt against the stored hashes. All
/// three must match — a partial match is still a failed recovery attempt,
/// since a security question is only as strong as its weakest answer.
bool verifyAnswers(List<String> answers, SecurityAnswerHash stored) {
  if (answers.length != stored.answerHashes.length) return false;
  for (var i = 0; i < answers.length; i++) {
    if (_hashAnswer(answers[i], stored.salt) != stored.answerHashes[i]) {
      return false;
    }
  }
  return true;
}

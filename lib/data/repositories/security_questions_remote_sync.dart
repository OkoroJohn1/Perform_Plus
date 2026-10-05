/// Security-question PIN recovery lives server-side (unlike the PIN itself,
/// which is local-only) because recovery has to work even if the device's
/// local secure storage is the very thing a student has lost access to —
/// a new phone, a wiped app, a reinstall. The student is already
/// authenticated via Supabase by the time this matters, so the row is
/// keyed on their auth uid with RLS scoping it to themselves alone, same
/// pattern as `profile_photo_remote_sync.dart`.
///
/// Only hashed answers ever leave the device — see
/// `domain/models/security_question.dart`'s `hashAnswers`/`verifyAnswers`,
/// which this repository never duplicates or second-guesses.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/security_question.dart';

abstract class SecurityQuestionsRemoteSync {
  /// Null if the student has never set up security questions.
  Future<SecurityAnswerHash?> fetch(String uid);

  Future<void> save(String uid, SecurityAnswerHash record);

  Future<void> clear(String uid);
}

class SupabaseSecurityQuestionsRemoteSync implements SecurityQuestionsRemoteSync {
  final SupabaseClient _client;

  SupabaseSecurityQuestionsRemoteSync(this._client);

  @override
  Future<SecurityAnswerHash?> fetch(String uid) async {
    final row = await _client
        .from('security_questions')
        .select('salt, question_1, answer_1_hash, question_2, answer_2_hash, question_3, answer_3_hash')
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return null;
    return SecurityAnswerHash(
      salt: row['salt'] as String,
      questions: [row['question_1'] as String, row['question_2'] as String, row['question_3'] as String],
      answerHashes: [
        row['answer_1_hash'] as String,
        row['answer_2_hash'] as String,
        row['answer_3_hash'] as String,
      ],
    );
  }

  @override
  Future<void> save(String uid, SecurityAnswerHash record) async {
    await _client.from('security_questions').upsert({
      'user_id': uid,
      'salt': record.salt,
      'question_1': record.questions[0],
      'answer_1_hash': record.answerHashes[0],
      'question_2': record.questions[1],
      'answer_2_hash': record.answerHashes[1],
      'question_3': record.questions[2],
      'answer_3_hash': record.answerHashes[2],
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> clear(String uid) async {
    await _client.from('security_questions').delete().eq('user_id', uid);
  }
}

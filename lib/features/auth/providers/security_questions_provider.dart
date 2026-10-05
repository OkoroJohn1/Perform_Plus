/// Security-question PIN recovery state. The record itself lives in
/// Supabase (`security_questions_remote_sync.dart`) — unlike the PIN, this
/// must survive a reinstall/new device, since it exists specifically for
/// when local state (the PIN) is the thing a student has lost access to.
///
/// [promptDismissed] is the one piece of UI-only state kept locally
/// (`local_settings`, matching `pinProvider`'s own `promptDismissed`) so the
/// one-time "add recovery questions" nudge doesn't nag every launch.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/security_question.dart';
import 'auth_provider.dart';

const _promptDismissedKey = 'securityQuestionsPromptDismissed';

class SecurityQuestionsState {
  final bool loaded;
  final bool hasQuestions;
  final bool promptDismissed;

  const SecurityQuestionsState({
    this.loaded = false,
    this.hasQuestions = false,
    this.promptDismissed = false,
  });

  SecurityQuestionsState copyWith({bool? loaded, bool? hasQuestions, bool? promptDismissed}) =>
      SecurityQuestionsState(
        loaded: loaded ?? this.loaded,
        hasQuestions: hasQuestions ?? this.hasQuestions,
        promptDismissed: promptDismissed ?? this.promptDismissed,
      );
}

class SecurityQuestionsController extends StateNotifier<SecurityQuestionsState> {
  final Ref _ref;

  SecurityQuestionsController(this._ref) : super(const SecurityQuestionsState()) {
    unawaited(_load());
  }

  String? get _uid => _ref.read(authStateProvider).valueOrNull?.userId;

  Future<void> _load() async {
    final dao = _ref.read(localSettingsDaoProvider);
    final dismissed = await dao.get(_promptDismissedKey);
    final uid = _uid;
    bool hasQuestions = false;
    if (uid != null) {
      final sync = _ref.read(securityQuestionsRemoteSyncProvider);
      if (sync != null) {
        try {
          hasQuestions = await sync.fetch(uid) != null;
        } catch (_) {
          // Offline at load time -- treated as "unknown, not missing"; the
          // dashboard prompt simply won't fire this session rather than
          // nagging a student who actually has questions set up already.
          hasQuestions = true;
        }
      }
    }
    state = state.copyWith(loaded: true, hasQuestions: hasQuestions, promptDismissed: dismissed == 'true');
  }

  /// Re-checks Supabase directly -- called after `save()` and after a
  /// sign-in, since [_uid] is null until auth resolves on a cold start.
  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) return;
    final sync = _ref.read(securityQuestionsRemoteSyncProvider);
    if (sync == null) return;
    final record = await sync.fetch(uid);
    state = state.copyWith(hasQuestions: record != null);
  }

  Future<void> save(List<String> questions, List<String> answers) async {
    final uid = _uid;
    if (uid == null) throw StateError('No signed-in student to save security questions for.');
    final sync = _ref.read(securityQuestionsRemoteSyncProvider);
    if (sync == null) throw StateError('No connection available to save security questions.');
    final record = hashAnswers(questions, answers);
    await sync.save(uid, record);
    state = state.copyWith(hasQuestions: true);
  }

  /// Fetches just the question text (never the hashes) for the recovery
  /// screen to display. Null if nothing is set up, or offline.
  Future<List<String>?> fetchQuestions() async {
    final uid = _uid;
    if (uid == null) return null;
    final sync = _ref.read(securityQuestionsRemoteSyncProvider);
    if (sync == null) return null;
    final record = await sync.fetch(uid);
    return record?.questions;
  }

  /// Verifies a recovery attempt. Re-fetches the stored hashes fresh each
  /// time rather than caching them client-side.
  Future<bool> verify(List<String> answers) async {
    final uid = _uid;
    if (uid == null) return false;
    final sync = _ref.read(securityQuestionsRemoteSyncProvider);
    if (sync == null) return false;
    final record = await sync.fetch(uid);
    if (record == null) return false;
    return verifyAnswers(answers, record);
  }

  Future<void> dismissPrompt() async {
    state = state.copyWith(promptDismissed: true);
    await _ref.read(localSettingsDaoProvider).set(_promptDismissedKey, 'true');
  }
}

final securityQuestionsProvider =
    StateNotifierProvider<SecurityQuestionsController, SecurityQuestionsState>(
  (ref) => SecurityQuestionsController(ref),
);

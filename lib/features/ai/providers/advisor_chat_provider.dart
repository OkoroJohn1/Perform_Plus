/// Persists the advisor chat conversation across navigation (and app
/// restarts) -- previously this lived in `_RealChatState`'s local widget
/// state, so leaving the chat screen and coming back (or killing the app)
/// silently lost everything typed. Stored as JSON under a single
/// `local_settings` key, the same lightweight pattern already used for
/// `themeAccent`/`pinAutoLockMinutes` -- a chat transcript is small text,
/// not structured data that needs its own table.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/daos/local_settings_dao.dart';
import '../../../data/repositories/repository_providers.dart';
import '../services/advisor_chat_service.dart';

const _advisorChatHistoryKey = 'advisorChatHistory';

/// Capped so the stored transcript (and the context window implicitly sent
/// on the next message, itself separately capped in advisor_chat_service.dart)
/// can't grow unbounded over months of use.
const advisorChatHistoryLimit = 60;

class AdvisorChatMessage {
  final bool isUser;
  final String text;
  final bool isError;

  /// True only for the single assistant bubble currently receiving streamed
  /// text -- lets the UI show a live cursor/typing cue on that bubble
  /// specifically rather than a separate phantom "typing..." row. Never
  /// true for anything loaded from storage; streaming is a this-request-only
  /// state, not something that survives a reload.
  final bool isStreaming;

  const AdvisorChatMessage({
    required this.isUser,
    required this.text,
    this.isError = false,
    this.isStreaming = false,
  });

  AdvisorChatMessage copyWith({String? text, bool? isStreaming}) => AdvisorChatMessage(
        isUser: isUser,
        text: text ?? this.text,
        isError: isError,
        isStreaming: isStreaming ?? this.isStreaming,
      );

  Map<String, dynamic> toJson() => {'isUser': isUser, 'text': text, 'isError': isError};

  factory AdvisorChatMessage.fromJson(Map<String, dynamic> json) => AdvisorChatMessage(
        isUser: json['isUser'] as bool? ?? false,
        text: json['text'] as String? ?? '',
        isError: json['isError'] as bool? ?? false,
      );
}

/// [sending] lives alongside the message list, not as a bare field on the
/// controller -- a plain field wouldn't trigger a rebuild when it flips,
/// since Riverpod's `StateNotifier` only notifies listeners on a `state`
/// assignment.
class AdvisorChatState {
  final List<AdvisorChatMessage> messages;
  final bool sending;

  const AdvisorChatState({this.messages = const [], this.sending = false});

  AdvisorChatState copyWith({List<AdvisorChatMessage>? messages, bool? sending}) => AdvisorChatState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
      );
}

class AdvisorChatHistoryController extends StateNotifier<AdvisorChatState> {
  final LocalSettingsDao? _dao;

  AdvisorChatHistoryController(this._dao) : super(const AdvisorChatState()) {
    unawaited(_load());
  }

  /// Fixed-state constructor for widget tests -- no Drift access.
  AdvisorChatHistoryController.seeded(List<AdvisorChatMessage> messages)
      : _dao = null,
        super(AdvisorChatState(messages: messages));

  Future<void> _load() async {
    final raw = await _dao?.get(_advisorChatHistoryKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List;
      state = state.copyWith(
        messages: decoded
            .whereType<Map>()
            .map((m) => AdvisorChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
    } catch (_) {
      // Corrupt/old-format stored JSON -- start fresh rather than crash the
      // chat screen over a transcript that was never load-bearing data.
    }
  }

  Future<void> _persist() async {
    final messages = state.messages;
    final capped = messages.length > advisorChatHistoryLimit
        ? messages.sublist(messages.length - advisorChatHistoryLimit)
        : messages;
    await _dao?.set(_advisorChatHistoryKey, jsonEncode(capped.map((m) => m.toJson()).toList()));
  }

  /// Replaces the LAST message in [state] with [updated] -- used to grow
  /// the streaming assistant bubble's text in place on every chunk, rather
  /// than re-rendering the whole list or leaving the student staring at a
  /// blank/typing bubble until the entire reply finishes generating.
  void _updateLastMessage(AdvisorChatMessage updated) {
    final messages = [...state.messages];
    if (messages.isEmpty) return;
    messages[messages.length - 1] = updated;
    state = state.copyWith(messages: messages);
  }

  Future<void> send(String text, {required Map<String, dynamic> context}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    // The conversation so far, BEFORE this new message is appended -- sent
    // to the function separately as `message`, not duplicated into `history`.
    final history = state.messages
        .where((m) => !m.isError)
        .map((m) => AdvisorChatTurn(isUser: m.isUser, text: m.text))
        .toList();

    state = state.copyWith(
      messages: [
        ...state.messages,
        AdvisorChatMessage(isUser: true, text: trimmed),
        const AdvisorChatMessage(isUser: false, text: '', isStreaming: true),
      ],
      sending: true,
    );
    await _persist();

    try {
      final reply = await sendAdvisorMessage(
        message: trimmed,
        context: context,
        history: history,
        onDelta: (textSoFar) =>
            _updateLastMessage(AdvisorChatMessage(isUser: false, text: textSoFar, isStreaming: true)),
      );
      _updateLastMessage(AdvisorChatMessage(isUser: false, text: reply));
      state = state.copyWith(sending: false);
    } on AdvisorChatException catch (e) {
      _updateLastMessage(AdvisorChatMessage(isUser: false, text: e.message, isError: true));
      state = state.copyWith(sending: false);
    } catch (_) {
      _updateLastMessage(
        const AdvisorChatMessage(isUser: false, text: 'Something went wrong. Try again.', isError: true),
      );
      state = state.copyWith(sending: false);
    }
    await _persist();
  }

  Future<void> clear() async {
    state = const AdvisorChatState();
    await _dao?.set(_advisorChatHistoryKey, '');
  }
}

final advisorChatHistoryProvider = StateNotifierProvider<AdvisorChatHistoryController, AdvisorChatState>(
  (ref) => AdvisorChatHistoryController(ref.watch(localSettingsDaoProvider)),
);

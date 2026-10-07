/// Client half of the `ai-advisor` Edge Function -- the chat counterpart to
/// `course_slip_extraction_service.dart`. The function call itself does the
/// actual LLM call server-side; this file only shapes the request and
/// surfaces a student-safe error message, mirroring that sibling service's
/// `SlipExtractionException` pattern.
///
/// Per AGENTS.md's "THE RULE THAT MATTERS MOST", [context] must always come
/// from `buildAdvisorChatContext` (`advisor_insights.dart`) -- already-
/// computed facts, never raw grades -- so this file has no way to send
/// anything else even by accident.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

/// One turn of the conversation, in the shape the Edge Function expects.
class AdvisorChatTurn {
  final bool isUser;
  final String text;

  const AdvisorChatTurn({required this.isUser, required this.text});

  Map<String, String> toJson() => {'role': isUser ? 'user' : 'assistant', 'content': text};
}

/// Thrown with a message that's always safe to show directly to the
/// student -- offline, rate-limited, service error, etc.
class AdvisorChatException implements Exception {
  final String message;
  const AdvisorChatException(this.message);

  @override
  String toString() => message;
}

/// Sends [message] plus the student's computed [context] and recent
/// [history] to the `ai-advisor` function and returns its reply.
///
/// [history] is capped to the last 8 turns before sending -- enough for the
/// model to track the thread without the per-message token cost (and bill)
/// growing unbounded across a long session, per AGENTS.md's cost-discipline
/// constraint.
Future<String> sendAdvisorMessage({
  required String message,
  required Map<String, dynamic> context,
  required List<AdvisorChatTurn> history,
}) async {
  const offlineMessage = "Couldn't reach the advisor. Check your connection and try again.";
  final recentHistory = history.length > 8 ? history.sublist(history.length - 8) : history;

  final Map<String, dynamic> data;
  try {
    final res = await Supabase.instance.client.functions.invoke(
      'ai-advisor',
      body: {
        'message': message,
        'context': context,
        'history': recentHistory.map((t) => t.toJson()).toList(),
      },
    );
    if (res.data is! Map) throw const AdvisorChatException(offlineMessage);
    data = Map<String, dynamic>.from(res.data as Map);
  } on FunctionException catch (e) {
    final details = e.details;
    final message = details is Map ? details['error'] as String? : null;
    throw AdvisorChatException(message ?? offlineMessage);
  } on AdvisorChatException {
    rethrow;
  } catch (_) {
    throw const AdvisorChatException(offlineMessage);
  }

  final reply = data['reply'];
  if (reply is! String || reply.trim().isEmpty) {
    throw const AdvisorChatException("Didn't get a clear answer back. Try asking again.");
  }
  return reply.trim();
}

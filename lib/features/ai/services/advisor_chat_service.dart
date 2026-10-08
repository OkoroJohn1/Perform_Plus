/// Client half of the `ai-advisor` Edge Function -- the chat counterpart to
/// `course_slip_extraction_service.dart`. The function call itself does the
/// actual LLM call server-side; this file only shapes the request and
/// surfaces a student-safe error message, mirroring that sibling service's
/// `SlipExtractionException` pattern.
///
/// Streams the reply token-by-token via [onDelta] instead of waiting for
/// the whole thing -- `supabase_flutter`'s `functions.invoke` buffers the
/// entire response before returning, which is exactly why the chat used to
/// feel slow: nothing appeared on screen until Anthropic finished
/// generating the full reply. A raw `package:http` streamed request against
/// the function's own URL (same auth the Supabase client would have sent)
/// lets each chunk of text reach the UI as it arrives instead.
///
/// Per AGENTS.md's "THE RULE THAT MATTERS MOST", [context] must always come
/// from `buildAdvisorChatContext` (`advisor_insights.dart`) -- already-
/// computed facts, never raw grades -- so this file has no way to send
/// anything else even by accident.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
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
/// [history] to the `ai-advisor` function, calling [onDelta] with the
/// accumulated reply text so far every time a new chunk arrives, and
/// returning the final complete reply once the stream ends.
///
/// [history] is capped to the last 8 turns before sending -- enough for the
/// model to track the thread without the per-message token cost (and bill)
/// growing unbounded across a long session, per AGENTS.md's cost-discipline
/// constraint.
Future<String> sendAdvisorMessage({
  required String message,
  required Map<String, dynamic> context,
  required List<AdvisorChatTurn> history,
  void Function(String textSoFar)? onDelta,
}) async {
  const offlineMessage = "Couldn't reach the advisor. Check your connection and try again.";
  final recentHistory = history.length > 8 ? history.sublist(history.length - 8) : history;

  final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (accessToken == null || supabaseUrl == null || anonKey == null) {
    throw const AdvisorChatException(offlineMessage);
  }

  final client = http.Client();
  try {
    final request = http.Request('POST', Uri.parse('$supabaseUrl/functions/v1/ai-advisor'))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'apikey': anonKey,
      })
      ..body = jsonEncode({
        'message': message,
        'context': context,
        'history': recentHistory.map((t) => t.toJson()).toList(),
      });

    final http.StreamedResponse streamed;
    try {
      streamed = await client.send(request);
    } catch (_) {
      throw const AdvisorChatException(offlineMessage);
    }

    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      throw AdvisorChatException(_extractErrorMessage(body) ?? offlineMessage);
    }

    final buffer = StringBuffer();
    String? streamError;

    await for (final line
        in streamed.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring(5).trim();
      if (payload.isEmpty) continue;

      final Map<String, dynamic> event;
      try {
        event = jsonDecode(payload) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }

      final delta = event['delta'];
      if (delta is String && delta.isNotEmpty) {
        buffer.write(delta);
        onDelta?.call(buffer.toString());
      } else if (event['error'] is String) {
        streamError = event['error'] as String;
      } else if (event['done'] == true) {
        break;
      }
    }

    final reply = buffer.toString().trim();
    if (reply.isEmpty) {
      throw AdvisorChatException(streamError ?? "Didn't get a clear answer back. Try asking again.");
    }
    // Keep whatever text already streamed even if a late error event also
    // arrived -- a mostly-complete answer is still more useful than none.
    return reply;
  } finally {
    client.close();
  }
}

String? _extractErrorMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded['error'] is String) return decoded['error'] as String;
  } catch (_) {
    // Non-JSON error body -- fall through to the caller's generic message.
  }
  return null;
}

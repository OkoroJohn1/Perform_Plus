/// The global chat entry point's sheet — opened by the AI tab's button and
/// by [AdvisorFab] on Home/Academics/Study.
///
/// Gated on [AppConstants.enableAdvisorChat] (now true): wired to the
/// `ai-advisor` Supabase Edge Function via `advisor_chat_service.dart`. The
/// model only ever receives [buildAdvisorChatContext]'s already-computed
/// payload plus the conversation text — never raw grades — per AGENTS.md's
/// "THE RULE THAT MATTERS MOST".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/repositories/goal_provider.dart';
import '../../../shared/widgets/advisor_mark.dart';
import '../../auth/providers/profile_provider.dart';
import '../services/advisor_chat_service.dart';
import '../services/advisor_insights.dart';

Future<void> showAdvisorChatSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AdvisorChatSheet(),
  );
}

class _AdvisorChatSheet extends ConsumerWidget {
  const _AdvisorChatSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standing = ref.watch(standingProvider);
    final record = ref.watch(academicRecordProvider);
    final goal = ref.watch(goalProvider);
    final goalProjection = ref.watch(targetProjectionProvider);
    final profile = ref.watch(studentProfileProvider);

    final state = buildAdvisorState(
      standing: standing,
      scheme: record.scheme,
      rawSemesters: record.semesters,
      goalBand: goal?.band,
      goalProjection: goalProjection,
      profile: profile,
      semestersRemaining: profile == null ? 0 : semestersRemainingFor(profile),
    );

    final activeTitles = state.isCritical
        ? ['Your CGPA is below the pass mark', ...state.insights.map((i) => i.title)]
        : state.insights.map((i) => i.title).toList();

    final chatContext = buildAdvisorChatContext(
      state: state,
      standing: standing,
      profile: profile,
      goalBand: goal?.band,
      goalProjection: goalProjection,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  const AdvisorMark(size: 32, simplified: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Performia',
                      style: TextStyle(
                        color: context.palette.bodyText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      icon: Icon(Icons.close, size: 24, color: context.palette.secondaryText),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFECECF1)),
            Expanded(
              child: AppConstants.enableAdvisorChat
                  ? _RealChat(context: chatContext, activeTitles: activeTitles)
                  : _ChatStub(scrollController: scrollController, activeTitles: activeTitles),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;
  final bool isError;

  const _ChatMessage({required this.isUser, required this.text, this.isError = false});
}

class _RealChat extends StatefulWidget {
  final Map<String, dynamic> context;
  final List<String> activeTitles;

  const _RealChat({required this.context, required this.activeTitles});

  @override
  State<_RealChat> createState() => _RealChatState();
}

class _RealChatState extends State<_RealChat> {
  final _messages = <_ChatMessage>[];
  final _textController = TextEditingController();
  final _listController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _textController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listController.hasClients) return;
      _listController.animateTo(
        _listController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;

    // The conversation so far, BEFORE this new message is appended -- it's
    // sent to the function separately as `message`, not duplicated into
    // `history`.
    final history = _messages
        .where((m) => !m.isError)
        .map((m) => AdvisorChatTurn(isUser: m.isUser, text: m.text))
        .toList();

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: trimmed));
      _sending = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final reply = await sendAdvisorMessage(message: trimmed, context: widget.context, history: history);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: reply));
        _sending = false;
      });
    } on AdvisorChatException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: e.message, isError: true));
        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _ChatMessage(isUser: false, text: 'Something went wrong. Try again.', isError: true),
        );
        _sending = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _EmptyChatPrompt(
                  activeTitles: widget.activeTitles,
                  onTapSuggestion: (title) => _send('Tell me more about "$title".'),
                )
              : ListView.builder(
                  controller: _listController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _messages.length) return const _TypingBubble();
                    return _ChatBubble(message: _messages[i]);
                  },
                ),
        ),
        _ChatInputBar(
          key: const ValueKey('advisorChatInputBar'),
          controller: _textController,
          sending: _sending,
          onSend: _send,
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isUser = message.isUser;
    final bubbleColor = isUser
        ? palette.primary
        : message.isError
            ? palette.errorBackground
            : palette.background;
    final textColor = isUser ? palette.onPrimary : (message.isError ? palette.error : palette.bodyText);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const Padding(padding: EdgeInsets.only(top: 2), child: AdvisorMark(size: 24, simplified: true)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(16)),
              child: Text(message.text, style: TextStyle(color: textColor, fontSize: 15, height: 1.35)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const AdvisorMark(size: 24, simplified: true),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: palette.background, borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChatPrompt extends StatelessWidget {
  final List<String> activeTitles;
  final ValueChanged<String> onTapSuggestion;

  const _EmptyChatPrompt({required this.activeTitles, required this.onTapSuggestion});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      children: [
        const Center(child: AdvisorMark(size: 64)),
        const SizedBox(height: 16),
        Text(
          'Ask me anything about your results',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.bodyText, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              "I'll answer using your real, computed CGPA and goal progress — never guessed numbers.",
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.secondaryText, fontSize: 14.5),
            ),
          ),
        ),
        if (activeTitles.isNotEmpty) ...[
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final title in activeTitles)
                Material(
                  color: palette.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onTapSuggestion(title),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text(
                        title,
                        style: TextStyle(color: palette.primary, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final ValueChanged<String> onSend;

  const _ChatInputBar({super.key, required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('advisorChatInput'),
                controller: controller,
                enabled: !sending,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: sending ? null : onSend,
                style: TextStyle(color: palette.bodyText, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Ask about your results…',
                  hintStyle: TextStyle(color: palette.hintText),
                  filled: true,
                  fillColor: palette.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: sending ? palette.disabledFill : palette.primary,
              shape: const CircleBorder(),
              child: InkWell(
                key: const ValueKey('advisorChatSendTap'),
                customBorder: const CircleBorder(),
                onTap: sending ? null : () => onSend(controller.text),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.arrow_upward, color: palette.onPrimary, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatStub extends StatelessWidget {
  final ScrollController scrollController;
  final List<String> activeTitles;

  const _ChatStub({required this.scrollController, required this.activeTitles});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      children: [
        const Center(
          child: Opacity(opacity: 0.4, child: AdvisorMark(size: 72)),
        ),
        const SizedBox(height: 20),
        Text(
          'Chat is coming soon',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'Your insights above are live and computed from your actual results. '
              'Conversational advice arrives in the next update.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.secondaryText, fontSize: 15.5),
            ),
          ),
        ),
        if (activeTitles.isNotEmpty) ...[
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final title in activeTitles)
                Material(
                  color: context.palette.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text(
                        title,
                        style: TextStyle(
                          color: context.palette.primary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The global chat entry point — opened by the AI tab's button and by
/// [AdvisorFab] on Home/Academics/Study. A real pushed screen with its own
/// back arrow/gesture, not a dismissible slide-up sheet -- a chat is
/// somewhere a student goes to and returns from, not a transient overlay.
///
/// Wired to the `ai-advisor` Supabase Edge Function via
/// `advisor_chat_service.dart`. The model only ever receives
/// [buildAdvisorChatContext]'s already-computed payload plus the
/// conversation text — including, as of the per-course breakdown, every
/// course/grade/credit-unit on record — but never a raw number it has to
/// compute itself (no CGPA/GPA/projection arithmetic), per AGENTS.md's "THE
/// RULE THAT MATTERS MOST".
library;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/repositories/goal_provider.dart';
import '../../../shared/widgets/advisor_mark.dart';
import '../../../shared/widgets/glass_top_bar.dart';
import '../../auth/providers/profile_provider.dart';
import '../providers/advisor_chat_provider.dart';
import '../services/advisor_insights.dart';

void openAdvisorChat(BuildContext context) => context.push(Routes.advisorChat);

class AdvisorChatScreen extends ConsumerWidget {
  const AdvisorChatScreen({super.key});

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
      rawSemesters: record.semesters,
      scheme: record.scheme,
      profile: profile,
      goalBand: goal?.band,
      goalProjection: goalProjection,
    );

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: const _AdvisorChatAppBar(),
      body: SafeArea(
        top: false,
        child: AppConstants.enableAdvisorChat
            ? _RealChat(context: chatContext, activeTitles: activeTitles)
            : _ChatStub(activeTitles: activeTitles),
      ),
    );
  }
}

class _AdvisorChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _AdvisorChatAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear this conversation?'),
        content: const Text('Your chat history with Performia will be deleted. This can’t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(
            key: const ValueKey('clearAdvisorChatConfirmTap'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(advisorChatHistoryProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMessages = ref.watch(advisorChatHistoryProvider.select((s) => s.messages.isNotEmpty));

    return TopBarGlassBackground(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    key: const ValueKey('advisorChatBackTap'),
                    icon: Icon(Icons.arrow_back, size: 24, color: context.palette.primary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(width: 4),
                const AdvisorMark(size: 28, simplified: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Performia',
                    style: TextStyle(
                      color: context.palette.bodyText,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (hasMessages)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      key: const ValueKey('clearAdvisorChatTap'),
                      icon: Icon(Icons.delete_outline, size: 22, color: context.palette.secondaryText),
                      tooltip: 'Clear conversation',
                      onPressed: () => _confirmClear(context, ref),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RealChat extends ConsumerStatefulWidget {
  final Map<String, dynamic> context;
  final List<String> activeTitles;

  const _RealChat({required this.context, required this.activeTitles});

  @override
  ConsumerState<_RealChat> createState() => _RealChatState();
}

class _RealChatState extends ConsumerState<_RealChat> {
  final _textController = TextEditingController();
  final _listController = ScrollController();

  /// True once the student has scrolled up away from the latest message --
  /// gates the "jump to latest" arrow above the input bar. Not simply "is
  /// there overflow": a short conversation that fits on screen has nothing
  /// to jump to, so the threshold is distance from the bottom, not content
  /// length.
  bool _showJumpToLatest = false;

  @override
  void initState() {
    super.initState();
    _listController.addListener(_updateJumpToLatest);
  }

  @override
  void dispose() {
    _listController.removeListener(_updateJumpToLatest);
    _textController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _updateJumpToLatest() {
    if (!_listController.hasClients) return;
    final distanceFromBottom = _listController.position.maxScrollExtent - _listController.position.pixels;
    final shouldShow = distanceFromBottom > 80;
    if (shouldShow != _showJumpToLatest) {
      setState(() => _showJumpToLatest = shouldShow);
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listController.hasClients) return;
      final target = _listController.position.maxScrollExtent;
      if (jump) {
        _listController.jumpTo(target);
      } else {
        _listController.animateTo(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _scrollToBottom();
    await ref.read(advisorChatHistoryProvider.notifier).send(text, context: widget.context);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // A streaming reply grows the LAST message's text on every chunk --
    // jump (not animate) to the bottom each time so the growing bubble
    // never scrolls out from under where the student is reading it.
    ref.listen(advisorChatHistoryProvider.select((s) => s.messages.lastOrNull?.text), (_, __) {
      _scrollToBottom(jump: true);
    });

    final chat = ref.watch(advisorChatHistoryProvider);
    final messages = chat.messages;

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _EmptyChatPrompt(
                  activeTitles: widget.activeTitles,
                  onTapSuggestion: (title) => _send('Tell me more about "$title".'),
                )
              : Stack(
                  children: [
                    ListView.builder(
                      controller: _listController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: messages.length,
                      itemBuilder: (context, i) => _ChatBubble(message: messages[i]),
                    ),
                    if (_showJumpToLatest)
                      Positioned(
                        right: 16,
                        bottom: 10,
                        child: _JumpToLatestButton(
                          key: const ValueKey('advisorChatJumpToLatestTap'),
                          onTap: () => _scrollToBottom(),
                        ),
                      ),
                  ],
                ),
        ),
        _ChatInputBar(
          key: const ValueKey('advisorChatInputBar'),
          controller: _textController,
          sending: chat.sending,
          onSend: _send,
        ),
      ],
    );
  }
}

class _JumpToLatestButton extends StatelessWidget {
  final VoidCallback onTap;

  const _JumpToLatestButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.keyboard_arrow_down, color: palette.primary, size: 22),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final AdvisorChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isUser = message.isUser;
    final bubbleColor = isUser
        ? palette.primary
        : message.isError
            ? palette.errorBackground
            : palette.surface;
    final textColor = isUser ? palette.onPrimary : (message.isError ? palette.error : palette.bodyText);
    // Nothing has streamed in yet -- show a typing cue in place of an empty
    // bubble rather than waiting for the first chunk to arrive.
    final stillWaiting = message.isStreaming && message.text.isEmpty;

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
              child: stillWaiting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
                    )
                  : Text(message.text, style: TextStyle(color: textColor, fontSize: 15, height: 1.35)),
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
                  fillColor: palette.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: palette.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: palette.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: palette.primary, width: 1.4),
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
  final List<String> activeTitles;

  const _ChatStub({required this.activeTitles});

  @override
  Widget build(BuildContext context) {
    return ListView(
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
                    onTap: () => Navigator.of(context).maybePop(),
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

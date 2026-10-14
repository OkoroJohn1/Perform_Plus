/// The Feedback tab — a shared, cross-student feed. Every submission lands
/// in Supabase's `app_feedback` table and is visible to every signed-in
/// student (see `SupabaseFeedbackRepository`'s doc comment for why this is
/// the one deliberate exception to this app's offline-first rule). A
/// student can submit at most once every 24 hours, enforced both here
/// (hides the form, shows a countdown) and server-side (a Postgres
/// trigger) — the server side is what actually holds if local state is
/// ever cleared or a different device is used.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/notification_provider.dart';
import '../../../domain/models/app_feedback.dart';
import '../../auth/providers/profile_provider.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/glass_top_bar.dart';
import '../../home/screens/notifications_panel.dart';
import '../providers/feedback_provider.dart';

/// The fixed meaning of each star value -- always shown alongside the
/// stars themselves, never a bare 1-5 number with no stated meaning.
const _starLabels = <int, String>{
  1: 'Poor — it did not work for me',
  2: 'Fair — it needs real work',
  3: 'Good — it does the job',
  4: 'Very good — I like using it',
  5: 'Excellent — I would recommend it',
};

String _relativeTime(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${at.day}/${at.month}/${at.year}';
}

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: palette.background,
        drawer: const AppDrawer(),
        appBar: const _FeedbackAppBar(),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => ref.read(feedbackControllerProvider.notifier).loadFeed(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: const [
                _SubmitCard(),
                SizedBox(height: 28),
                _FeedSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FeedbackAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return TopBarGlassBackground(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Builder(
                  builder: (context) => Material(
                    color: context.palette.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.menu, size: 22, color: context.palette.primary),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Feedback',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                ),
                const _FeedbackBell(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reuses the same in-app notification inbox every other tab's bell
/// opens -- feedback doesn't generate notifications of its own, but a
/// student browsing this tab shouldn't lose access to the one they
/// already have from here.
class _FeedbackBell extends ConsumerWidget {
  const _FeedbackBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider.select((n) => n.any((x) => !x.isRead)));
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          Center(
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 24, color: Color(0xFF4B5563)),
              onPressed: () => showNotificationsPanel(context),
            ),
          ),
          if (unread)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: context.palette.error, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubmitCard extends ConsumerStatefulWidget {
  const _SubmitCard();

  @override
  ConsumerState<_SubmitCard> createState() => _SubmitCardState();
}

class _SubmitCardState extends ConsumerState<_SubmitCard> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _showName = false;

  @override
  void initState() {
    super.initState();
    // The submit button's enabled state depends on the comment's trimmed
    // length -- without this listener, typing never rebuilds this widget
    // (nothing else here calls setState on keystrokes), so the button
    // stayed stuck at whatever enabled/disabled state it had before the
    // first character was typed.
    _commentController.addListener(_onCommentChanged);
  }

  void _onCommentChanged() => setState(() {});

  @override
  void dispose() {
    _commentController.removeListener(_onCommentChanged);
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final profile = ref.read(studentProfileProvider);
    final ok = await ref.read(feedbackControllerProvider.notifier).submit(
          rating: _rating,
          comment: _commentController.text,
          showName: _showName,
          localFullName: profile?.fullName,
        );
    if (ok && mounted) {
      _commentController.clear();
      setState(() => _rating = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — your feedback is live on the feed.')),
      );
    } else if (mounted) {
      final error = ref.read(feedbackControllerProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(feedbackControllerProvider);
    final canSubmit = state.lastSubmittedAt != null && state.canSubmitNow;
    final remaining = state.timeUntilNextSubmission;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primaryGradientStart, palette.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: palette.primary.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How is Perform+ working for you?',
            style: TextStyle(color: palette.onPrimary, fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Your rating and comment post to the shared feed below for every student to see.',
            style: TextStyle(color: palette.onPrimary.withValues(alpha: 0.85), fontSize: 13.5),
          ),
          const SizedBox(height: 20),
          if (state.lastSubmittedAt == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(strokeWidth: 2, color: palette.onPrimary),
              ),
            )
          else if (!canSubmit)
            _CooldownNotice(remaining: remaining)
          else ...[
            _StarRow(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _rating == 0
                  ? const SizedBox(height: 20)
                  : Text(
                      _starLabels[_rating]!,
                      key: ValueKey(_rating),
                      style: TextStyle(
                        color: palette.onPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                key: const ValueKey('feedbackCommentField'),
                controller: _commentController,
                maxLines: 4,
                maxLength: 1000,
                style: TextStyle(color: palette.bodyText, fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: 'What should we know?',
                  hintStyle: TextStyle(color: palette.hintText),
                  contentPadding: const EdgeInsets.all(14),
                  border: InputBorder.none,
                  counterStyle: TextStyle(color: palette.secondaryText, fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  key: const ValueKey('feedbackShowNameSwitch'),
                  value: _showName,
                  onChanged: (v) => setState(() => _showName = v),
                  activeTrackColor: palette.onPrimary.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.all(palette.onPrimary),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Show my name instead of posting anonymously',
                    style: TextStyle(color: palette.onPrimary.withValues(alpha: 0.9), fontSize: 12.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('feedbackSubmitTap'),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.onPrimary,
                  foregroundColor: palette.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: (_rating > 0 && _commentController.text.trim().isNotEmpty && !state.submitting)
                    ? _submit
                    : null,
                child: state.submitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
                      )
                    : const Text('Submit feedback', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CooldownNotice extends StatelessWidget {
  final Duration? remaining;

  const _CooldownNotice({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final r = remaining;
    final hoursLeft = r == null ? 0 : (r.inMinutes / 60).ceil().clamp(1, 24);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: palette.onPrimary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              r == null
                  ? "Thanks for your feedback — you're clear to share again."
                  : 'Thanks for your feedback! You can share again in about $hoursLeft'
                      "${hoursLeft == 1 ? ' hour' : ' hours'}.",
              style: TextStyle(color: palette.onPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _StarRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final onPrimary = context.palette.onPrimary;
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              key: ValueKey('feedbackStarTap$i'),
              customBorder: const CircleBorder(),
              onTap: () => onChanged(i),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 32,
                  color: onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeedSection extends ConsumerWidget {
  const _FeedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final state = ref.watch(feedbackControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Everyone's feedback",
          style: TextStyle(color: palette.bodyText, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        if (state.loadingFeed)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (state.error != null && state.feed.isEmpty)
          _FeedMessage(
            icon: Icons.wifi_off_rounded,
            text: state.error!,
          )
        else if (state.feed.isEmpty)
          const _FeedMessage(
            icon: Icons.forum_outlined,
            text: 'No feedback yet — be the first to share what you think.',
          )
        else
          Column(
            children: [for (final entry in state.feed) _FeedRow(entry: entry)],
          ),
      ],
    );
  }
}

class _FeedMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeedMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.surfaceBorder, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: palette.secondaryText),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.secondaryText, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  final AppFeedback entry;

  const _FeedRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.surfaceBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= entry.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: palette.amber,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                _relativeTime(entry.createdAt),
                style: TextStyle(color: palette.secondaryText, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.comment,
            style: TextStyle(color: palette.bodyText, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            entry.isAnonymous ? 'Anonymous student' : entry.displayName!,
            style: TextStyle(color: palette.secondaryText, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

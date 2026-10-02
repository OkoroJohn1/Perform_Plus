/// The global chat entry point's sheet — opened by the AI tab's button and
/// by [AdvisorFab] on Home/Academics/Study.
///
/// Gated on [AppConstants.enableAdvisorChat] (currently false): until a
/// real backend exists — a Supabase Edge Function proxy, function-calling
/// only, the API key never in the client — this is an honest "coming soon"
/// placeholder, not a chat input that goes nowhere and not scripted canned
/// replies. A student who types a real question and gets a non-answer
/// won't come back when the feature actually works.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/repositories/goal_provider.dart';
import '../../../shared/widgets/advisor_mark.dart';
import '../../auth/providers/profile_provider.dart';
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
                  ? const _RealChatNotYetBuilt()
                  : _ChatStub(scrollController: scrollController, activeTitles: activeTitles),
            ),
          ],
        ),
      ),
    );
  }
}

/// Swap-in point for the real implementation once `enableAdvisorChat`
/// flips — see this file's doc comment.
class _RealChatNotYetBuilt extends StatelessWidget {
  const _RealChatNotYetBuilt();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
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

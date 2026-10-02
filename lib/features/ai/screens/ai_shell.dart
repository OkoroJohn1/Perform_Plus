/// AI Advisor tab.
///
/// ⚠ THE RULE THAT MATTERS MOST (see AGENTS.md): the LLM never performs
/// arithmetic. Every number below comes from [CgpaEngine]/[ProjectionSolver]
/// via [buildAdvisorState] — a pure template engine, not a model call. When
/// chat is wired later, the model receives only
/// [TargetProjection.toAdvisorPayload] and phrases it; it is never handed
/// raw grades and asked a maths question. These cards work today with no
/// API key precisely because they're deterministic and verifiable — do not
/// route them through an LLM.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/repositories/goal_provider.dart';
import '../../../data/repositories/notification_provider.dart';
import '../../../domain/engine/projection_solver.dart';
import '../../../shared/widgets/advisor_mark.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../auth/providers/profile_provider.dart';
import '../../home/screens/notifications_panel.dart';
import '../services/advisor_insights.dart';
import 'advisor_chat_sheet.dart';

String _fmt(double v) => v.toStringAsFixed(2);

extension _InsightPresentation on Insight {
  IconData get icon => switch (kind) {
        InsightKind.goalPace => Icons.flag_outlined,
        InsightKind.trend => switch (trendDirection!) {
            TrendDirection.rising => Icons.trending_up,
            TrendDirection.falling => Icons.trending_down,
            TrendDirection.steady => Icons.trending_flat,
          },
        InsightKind.weakestCreditLoad => Icons.priority_high,
        InsightKind.carryovers => Icons.replay,
        InsightKind.nextEntry => Icons.add_chart,
        InsightKind.insufficientData => Icons.info_outline,
      };

  Color colorFor(AppPalette palette) => switch (kind) {
        InsightKind.goalPace => switch (feasibility!) {
            Feasibility.secured || Feasibility.comfortable => FeasibilityPalette.secured,
            Feasibility.withinReach => FeasibilityPalette.withinReach,
            Feasibility.demanding => FeasibilityPalette.demanding,
            Feasibility.extremelyDemanding => FeasibilityPalette.extremelyDemanding,
            Feasibility.unreachable => FeasibilityPalette.unreachable,
          },
        InsightKind.trend => switch (trendDirection!) {
            TrendDirection.rising => palette.success,
            TrendDirection.falling => palette.amber,
            TrendDirection.steady => palette.primary,
          },
        InsightKind.weakestCreditLoad => palette.amber,
        InsightKind.carryovers => palette.amber,
        InsightKind.nextEntry => palette.primary,
        InsightKind.insufficientData => palette.secondaryText,
      };
}

class AiShell extends ConsumerWidget {
  const AiShell({super.key});

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

    final firstName = _firstName(profile?.fullName);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: context.palette.background,
        drawer: const AppDrawer(),
        appBar: const _AiAppBar(),
        body: SafeArea(
          top: false,
          child: !standing.hasData
              ? _EmptyAdvisor(firstName: firstName)
              : ListView(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  children: [
                    _GreetingCard(firstName: firstName, isCritical: state.isCritical),
                    if (state.isCritical) ...[
                      const SizedBox(height: 20),
                      _CriticalStandingCard(critical: state.critical!),
                    ],
                    if (state.insights.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Your insights',
                          style: TextStyle(
                            color: context.palette.bodyText,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InsightsContainer(insights: state.insights),
                    ],
                    const SizedBox(height: 24),
                    _AskButton(onPressed: () => showAdvisorChatSheet(context)),
                  ],
                ),
        ),
      ),
    );
  }

  static String _firstName(String? fullName) {
    if (fullName == null) return 'there';
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'there' : parts.first;
  }
}

class _AiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AiAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DashboardPalette.scaffoldBackground,
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
                    'Performia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.palette.bodyText,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const _NotificationBell(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

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

class _GreetingCard extends StatelessWidget {
  final String firstName;
  final bool isCritical;

  const _GreetingCard({required this.firstName, required this.isCritical});

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.14), context.palette.surface],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.16), width: 1.2),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: AdvisorMark(size: 52, neutral: isCritical),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi $firstName',
                  style: TextStyle(
                    color: context.palette.bodyText,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isCritical
                      ? "Here's where your record stands."
                      : "Here's what your numbers say about your goal.",
                  style: TextStyle(color: context.palette.secondaryText, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A fact about arithmetic, not an error the student made — grey, never
/// red; states the number once, shows what it would take, and routes to a
/// person with actual authority. See this file's constraints in the task
/// brief for everything this card must NOT say.
class _CriticalStandingCard extends StatelessWidget {
  final CriticalStanding critical;

  const _CriticalStandingCard({required this.critical});

  @override
  Widget build(BuildContext context) {
    final projection = critical.projectionToLowestBand;
    final whatItWouldTake = projection.feasibility == Feasibility.unreachable
        ? "That isn't reachable in the semesters you have left."
        : "To reach ${critical.lowestBand.label} you'd need to average "
            '${projection.requiredAverage != null ? _fmt(projection.requiredAverage!) : '—'} '
            'across your remaining ${projection.semestersRemaining} semesters.';

    return Container(
      key: const ValueKey('criticalStandingCard'),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.palette.bodyText.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 24, color: context.palette.secondaryText),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your CGPA is below the pass mark',
                  style: TextStyle(
                    color: context.palette.secondaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your CGPA is ${_fmt(critical.cgpa)}. ${critical.institutionName}\'s lowest '
            'classification starts at ${_fmt(critical.lowestBand.minCgpa)}.',
            style: TextStyle(color: context.palette.bodyText, fontSize: 15.5),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, color: Color(0xFFECECF1)),
          ),
          Row(
            children: [
              Icon(Icons.calculate_outlined, size: 20, color: context.palette.primary),
              const SizedBox(width: 10),
              Text(
                'What it would take',
                style: TextStyle(color: context.palette.primary, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(whatItWouldTake, style: TextStyle(color: context.palette.bodyText, fontSize: 15.5)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, color: Color(0xFFECECF1)),
          ),
          Row(
            children: [
              Icon(Icons.support_agent, size: 20, color: context.palette.primary),
              const SizedBox(width: 10),
              Text(
                'Talk to your academic adviser',
                style: TextStyle(color: context.palette.primary, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your department decides what happens next — probation, extra semesters, or an '
            "appeal. Those options aren't visible in your results, and this app can't see them.",
            style: TextStyle(color: context.palette.bodyText, fontSize: 15.5),
          ),
          const SizedBox(height: 16),
          Text(
            "If you're carrying more than the grades, your school's counselling unit is there "
            'for that too.',
            style: TextStyle(color: context.palette.secondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _InsightsContainer extends StatelessWidget {
  final List<Insight> insights;

  const _InsightsContainer({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.palette.bodyText.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < insights.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 76, color: context.palette.divider),
            _InsightRow(insight: insights[i]),
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final Insight insight;

  const _InsightRow({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = insight.colorFor(context.palette);

    return InkWell(
      onTap: () => _showInsightDetail(context, insight),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(insight.icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: TextStyle(color: color, fontSize: 17.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.palette.bodyText, fontSize: 15.5),
                  ),
                  if (insight.warning != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      insight.warning!,
                      style: TextStyle(color: context.palette.amber, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 22, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

void _showInsightDetail(BuildContext context, Insight insight) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              insight.title,
              style: TextStyle(color: insight.colorFor(context.palette), fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(insight.body, style: TextStyle(color: context.palette.bodyText, fontSize: 16)),
            if (insight.warning != null) ...[
              const SizedBox(height: 8),
              Text(insight.warning!, style: TextStyle(color: context.palette.amber, fontSize: 14)),
            ],
          ],
        ),
      ),
    ),
  );
}

class _AskButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AskButton({required this.onPressed});

  @override
  State<_AskButton> createState() => _AskButtonState();
}

class _AskButtonState extends State<_AskButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        key: const ValueKey('askAboutResultsButtonTap'),
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _pressed ? 0.98 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _pressed ? context.palette.primary : null,
              gradient: _pressed
                  ? null
                  : LinearGradient(
                      colors: [context.palette.primaryGradientStart, context.palette.primary],
                    ),
              boxShadow: [
                BoxShadow(
                  color: context.palette.primary.withValues(alpha: 0.22),
                  blurRadius: _pressed ? 4 : 16,
                  offset: _pressed ? Offset.zero : const Offset(0, 6),
                ),
                if (!_pressed)
                  BoxShadow(
                    color: context.palette.primary.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 20, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Ask about your results',
                  style: TextStyle(color: Colors.white, fontSize: 17.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyAdvisor extends StatelessWidget {
  final String firstName;

  const _EmptyAdvisor({required this.firstName});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        _GreetingCard(firstName: firstName, isCritical: false),
        const SizedBox(height: 40),
        const Icon(Icons.insights_outlined, size: 44, color: Color(0xFFD1D5DB)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            "Add a semester and I'll have something to say",
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.secondaryText, fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton(
            onPressed: () => context.go(Routes.academics),
            child: const Text('Add results'),
          ),
        ),
      ],
    );
  }
}

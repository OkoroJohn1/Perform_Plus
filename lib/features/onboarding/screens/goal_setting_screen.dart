/// Goal setting — Act 2 step 4 of 4, the final onboarding screen.
///
/// Turns a calculator into an advisor: every later screen is framed
/// against the answer given here. Every number on this screen comes from
/// `ProjectionSolver` — never computed in the widget layer, never a
/// fabricated percentage. The most damaging mistake this screen could make
/// is showing the classification threshold ("you need 4.50") instead of
/// the solved required average ("you need 4.88") — see
/// `TargetProjection.requiredAverage` and `_RequiredAverageBlock` below.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/repositories/goal_provider.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/engine/projection_solver.dart';
import '../../../domain/models/grading_scheme.dart';
import '../../../shared/widgets/onboarding_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/profile_provider.dart';

const _saveTimeout = Duration(seconds: 15);

String _fmt(double v) => v.toStringAsFixed(2);

/// Feasibility -> presentation. Lives here (not in the pure domain layer)
/// because it maps a domain enum to `Color`/`IconData` — see
/// `projection_solver.dart`'s purity contract.
extension _FeasibilityPresentation on Feasibility {
  Color get color => switch (this) {
        Feasibility.secured || Feasibility.comfortable => FeasibilityPalette.secured,
        Feasibility.withinReach => FeasibilityPalette.withinReach,
        Feasibility.demanding => FeasibilityPalette.demanding,
        Feasibility.extremelyDemanding => FeasibilityPalette.extremelyDemanding,
        Feasibility.unreachable => FeasibilityPalette.unreachable,
      };

  double get surfaceAlpha =>
      this == Feasibility.demanding || this == Feasibility.extremelyDemanding
          ? 0.08
          : 0.06;

  IconData get icon => switch (this) {
        Feasibility.secured => Icons.verified_outlined,
        Feasibility.comfortable => Icons.trending_flat,
        Feasibility.withinReach => Icons.trending_up,
        Feasibility.demanding => Icons.priority_high,
        Feasibility.extremelyDemanding => Icons.warning_amber_outlined,
        Feasibility.unreachable => Icons.info_outline,
      };
}

class GoalSettingScreen extends ConsumerStatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  ConsumerState<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends ConsumerState<GoalSettingScreen> {
  ClassificationBand? _selectedBand;
  double? _customTarget;
  bool _defaultChosen = false;
  bool _saving = false;

  /// Runs at most once — after that the student is in control. Chooses the
  /// highest band still `withinReach` or better, NEVER automatically First
  /// Class: defaulting to an unreachable goal starts the student in failure.
  void _chooseDefaultIfNeeded(GradingScheme scheme, List<TargetProjection> projections) {
    if (_defaultChosen) return;
    _defaultChosen = true;
    final within = projections
        .where((p) => p.feasibility.index <= Feasibility.withinReach.index);
    final chosenLabel =
        within.isNotEmpty ? within.first.targetLabel : projections.last.targetLabel;
    _selectedBand = scheme.bandsDescending.firstWhere(
      (b) => b.label == chosenLabel,
      orElse: () => scheme.bandsDescending.first,
    );
  }

  double _targetCgpa(GradingScheme scheme) =>
      _customTarget ?? _selectedBand?.minCgpa ?? scheme.bandsDescending.first.minCgpa;

  String? get _targetLabel => _customTarget != null ? null : _selectedBand?.label;

  Future<void> _openPicker(GradingScheme scheme, List<TargetProjection> projections) async {
    final result = await showModalBottomSheet<_PickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OnboardingLightPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Theme(
        data: AppTheme.onboardingLight,
        child: _TargetPickerSheet(scheme: scheme, projections: projections),
      ),
    );
    if (result == null) return;
    setState(() {
      _selectedBand = result.band;
      _customTarget = result.custom;
    });
  }

  void _setNearestAchievable(ClassificationBand band) {
    setState(() {
      _selectedBand = band;
      _customTarget = null;
    });
  }

  Future<void> _handleSave(ClassificationBand band, int semestersRemaining) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(goalProvider.notifier)
          .save(GoalTarget(band: band, semestersRemaining: semestersRemaining))
          .timeout(_saveTimeout);
      await ref.read(authStateProvider.notifier).markOnboardingComplete();
      if (!mounted) return;
      context.go(Routes.home);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your goal. Please try again.')),
      );
    }
  }

  /// Skipping still finishes Act 2 -- goal setting itself is optional, but
  /// "I skipped it" is a completed state, not an interrupted one.
  Future<void> _skip() async {
    await ref.read(authStateProvider.notifier).markOnboardingComplete();
    if (!mounted) return;
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final standing = ref.watch(standingProvider);
    final scheme = ref.watch(academicRecordProvider).scheme;
    final profile = ref.watch(studentProfileProvider);

    return Theme(
      data: AppTheme.onboardingLight,
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: colorScheme.surface,
              body: SafeArea(
                child: Column(
                  children: [
                    OnboardingHeader(
                      stepNumber: AccountSetupStep.goal.stepNumber,
                      totalSteps: AccountSetupStep.totalSteps,
                      title: 'Set Your Goal',
                      onBack: () => context.go(Routes.backfill),
                    ),
                    Expanded(
                      child: !standing.hasData
                          ? _NoResultsYet(
                              onAddResults: () => context.go(Routes.addFirstResults),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: _buildCard(standing, scheme, profile),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(
    AcademicStanding standing,
    GradingScheme scheme,
    StudentProfile? profile,
  ) {
    final semestersRemaining =
        profile != null ? semestersRemainingFor(profile) : 0;
    final projections = ProjectionSolver.allBandProjections(
      standing: standing,
      scheme: scheme,
      semestersRemaining: semestersRemaining,
    );
    _chooseDefaultIfNeeded(scheme, projections);

    final targetCgpa = _targetCgpa(scheme);
    final projection = ProjectionSolver.solveForTarget(
      standing: standing,
      scheme: scheme,
      targetCgpa: targetCgpa,
      targetLabel: _targetLabel,
      semestersRemaining: semestersRemaining,
    );

    final semestersWithData =
        standing.semesters.where((s) => s.creditUnits > 0).length;
    final hasEnoughData = semestersWithData >= 2;
    final showRequiredAverage =
        projection.requiredAverage != null && projection.isReachable;
    final showCoasting = projection.coastingCgpa != standing.cgpa;

    final selectedBandForSave = _selectedBand ??
        ClassificationBand(
          label: 'Custom (${_fmt(targetCgpa)})',
          shortLabel: 'Custom',
          minCgpa: targetCgpa,
          maxCgpa: targetCgpa,
        );

    return _GoalCard(
      pickerLabel: _targetLabel ?? 'Custom · ${_fmt(targetCgpa)} CGPA',
      onOpenPicker: () => _openPicker(scheme, projections),
      showRequiredAverage: showRequiredAverage,
      requiredAverage: projection.requiredAverage,
      semestersRemaining: semestersRemaining,
      feasibilityColor: projection.feasibility.color,
      standing: standing,
      hasEnoughData: hasEnoughData,
      showCoasting: showCoasting,
      coastingClassification: scheme.classify(projection.coastingCgpa),
      hasEnoughDataForFeasibility: hasEnoughData,
      projection: projection,
      scheme: scheme,
      onSetNearestAchievable: _setNearestAchievable,
      onAddPastSemesters: () => context.go(Routes.backfill),
      saving: _saving,
      onSave: () => _handleSave(selectedBandForSave, semestersRemaining),
      onSkip: () => _skip(),
    );
  }
}

class _PickerResult {
  final ClassificationBand? band;
  final double? custom;
  const _PickerResult.band(this.band) : custom = null;
  const _PickerResult.custom(this.custom) : band = null;
}

class _NoResultsYet extends StatelessWidget {
  final VoidCallback onAddResults;
  const _NoResultsYet({required this.onAddResults});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_outlined, size: 40, color: OnboardingLightPalette.emptyIcon),
            const SizedBox(height: 16),
            Text(
              'Add results first',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your goal is measured against your own results — add at '
              'least one semester first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: OnboardingLightPalette.secondaryText, fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAddResults,
              child: Text(
                'Add your results',
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String pickerLabel;
  final VoidCallback onOpenPicker;
  final bool showRequiredAverage;
  final double? requiredAverage;
  final int semestersRemaining;
  final Color feasibilityColor;
  final AcademicStanding standing;
  final bool hasEnoughData;
  final bool showCoasting;
  final ClassificationBand? coastingClassification;
  final bool hasEnoughDataForFeasibility;
  final TargetProjection projection;
  final GradingScheme scheme;
  final ValueChanged<ClassificationBand> onSetNearestAchievable;
  final VoidCallback onAddPastSemesters;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onSkip;

  const _GoalCard({
    required this.pickerLabel,
    required this.onOpenPicker,
    required this.showRequiredAverage,
    required this.requiredAverage,
    required this.semestersRemaining,
    required this.feasibilityColor,
    required this.standing,
    required this.hasEnoughData,
    required this.showCoasting,
    required this.coastingClassification,
    required this.hasEnoughDataForFeasibility,
    required this.projection,
    required this.scheme,
    required this.onSetNearestAchievable,
    required this.onAddPastSemesters,
    required this.saving,
    required this.onSave,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: OnboardingLightPalette.searchBorder, width: 1.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "What's your goal?",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Target Classification',
            style: TextStyle(
              color: OnboardingLightPalette.labelText,
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _PickerField(label: pickerLabel, onTap: onOpenPicker),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: showRequiredAverage
                ? _RequiredAverageBlock(
                    key: const ValueKey('required-average'),
                    requiredAverage: requiredAverage!,
                    semestersRemaining: semestersRemaining,
                    color: feasibilityColor,
                  )
                : const SizedBox.shrink(key: ValueKey('no-required-average')),
          ),
          if (showRequiredAverage) const SizedBox(height: 20),
          _CurrentStandingBlock(
            standing: standing,
            hasEnoughData: hasEnoughData,
            showCoasting: showCoasting,
            coastingCgpa: projection.coastingCgpa,
            coastingClassification: coastingClassification,
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: !hasEnoughDataForFeasibility
                ? _InsufficientDataCard(
                    key: const ValueKey('insufficient-data'),
                    onAddPastSemesters: onAddPastSemesters,
                  )
                : _FeasibilityCard(
                    key: ValueKey('feasibility-${projection.feasibility}-${projection.targetLabel}'),
                    projection: projection,
                    scheme: scheme,
                    onSetNearestAchievable: onSetNearestAchievable,
                  ),
          ),
          const SizedBox(height: 26),
          _SaveButton(saving: saving, onPressed: onSave),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              height: 44,
              child: TextButton(
                onPressed: saving ? null : onSkip,
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    color: OnboardingLightPalette.secondaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PickerField({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const ValueKey('targetPickerFieldTap'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OnboardingLightPalette.searchBorder, width: 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.expand_more, size: 24, color: OnboardingLightPalette.hintText),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequiredAverageBlock extends StatelessWidget {
  final double requiredAverage;
  final int semestersRemaining;
  final Color color;

  const _RequiredAverageBlock({
    super.key,
    required this.requiredAverage,
    required this.semestersRemaining,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          'You need to average',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 17.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        _AnimatedGpaNumber(value: requiredAverage, color: color),
        const SizedBox(height: 4),
        Text(
          'across your remaining $semestersRemaining '
          '${semestersRemaining == 1 ? 'semester' : 'semesters'}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: OnboardingLightPalette.secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// Smoothly animates to a new [value] whenever it changes, rather than
/// snapping — the number is the single most important figure on the
/// screen, and a jump cut undersells that it just changed for a reason.
class _AnimatedGpaNumber extends StatefulWidget {
  final double value;
  final Color color;
  const _AnimatedGpaNumber({required this.value, required this.color});

  @override
  State<_AnimatedGpaNumber> createState() => _AnimatedGpaNumberState();
}

class _AnimatedGpaNumberState extends State<_AnimatedGpaNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = AlwaysStoppedAnimation(widget.value);
  }

  @override
  void didUpdateWidget(covariant _AnimatedGpaNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: oldWidget.value, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Text(
        '${_fmt(_animation.value)} GPA',
        style: TextStyle(color: widget.color, fontSize: 32, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CurrentStandingBlock extends StatelessWidget {
  final AcademicStanding standing;
  final bool hasEnoughData;
  final bool showCoasting;
  final double coastingCgpa;
  final ClassificationBand? coastingClassification;

  const _CurrentStandingBlock({
    required this.standing,
    required this.hasEnoughData,
    required this.showCoasting,
    required this.coastingCgpa,
    required this.coastingClassification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OnboardingLightPalette.standingFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StandingRow(label: 'Current CGPA', value: _fmt(standing.cgpa)),
          if (hasEnoughData && standing.bestSemesterGpa != null) ...[
            const SizedBox(height: 14),
            _StandingRow(label: 'Best semester yet', value: _fmt(standing.bestSemesterGpa!)),
          ],
          if (showCoasting) ...[
            const SizedBox(height: 14),
            _StandingRow(label: 'If you keep this pace', value: _fmt(coastingCgpa)),
            const SizedBox(height: 2),
            Text(
              coastingClassification != null
                  ? '${coastingClassification!.shortLabel} territory'
                  : 'Below Pass territory',
              style: const TextStyle(
                color: OnboardingLightPalette.secondaryText,
                fontSize: 14.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final String label;
  final String value;
  const _StandingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: OnboardingLightPalette.secondaryText, fontSize: 15.5),
        ),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InsufficientDataCard extends StatelessWidget {
  final VoidCallback onAddPastSemesters;
  const _InsufficientDataCard({super.key, required this.onAddPastSemesters});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add more semesters for a sharper read',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'With one semester on record we can compute what you '
                  'need, but not how it compares to your usual performance.',
                  style: TextStyle(color: OnboardingLightPalette.secondaryText, fontSize: 14),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onAddPastSemesters,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    'Add past semesters',
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeasibilityCard extends StatelessWidget {
  final TargetProjection projection;
  final GradingScheme scheme;
  final ValueChanged<ClassificationBand> onSetNearestAchievable;

  const _FeasibilityCard({
    super.key,
    required this.projection,
    required this.scheme,
    required this.onSetNearestAchievable,
  });

  @override
  Widget build(BuildContext context) {
    if (projection.feasibility == Feasibility.unreachable) {
      return _UnreachableCard(
        projection: projection,
        scheme: scheme,
        onSetNearestAchievable: onSetNearestAchievable,
      );
    }

    final color = projection.feasibility.color;
    final (title, body) = _copyFor(projection);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: projection.feasibility.surfaceAlpha),
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(projection.feasibility.icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  maxLines: 3,
                  style: const TextStyle(
                    color: OnboardingLightPalette.bodyText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _copyFor(TargetProjection p) {
    final req = p.requiredAverage != null ? _fmt(p.requiredAverage!) : '—';
    final cgpa = _fmt(p.currentCgpa);
    final best = p.personalBest != null ? _fmt(p.personalBest!) : '—';
    final max = _fmt(scheme.maxPoint);

    return switch (p.feasibility) {
      Feasibility.secured => (
          'Already secured',
          'Your current CGPA already meets this. Maintain it and it\'s yours.',
        ),
      Feasibility.comfortable => (
          'Comfortable',
          'You need $req — below your current $cgpa. Steady work holds this.',
        ),
      Feasibility.withinReach => (
          'Within reach',
          'You need $req. You\'ve hit $best before, so this is proven ground.',
        ),
      Feasibility.demanding => (
          'Demanding',
          'You need $req — above your best semester of $best. It means '
              'beating your personal best every remaining semester.',
        ),
      Feasibility.extremelyDemanding => (
          'Extremely demanding',
          'You need $req, near the $max maximum. This requires close to '
              'perfect grades in every remaining course.',
        ),
      Feasibility.unreachable => ('', ''), // handled by _UnreachableCard
    };
  }
}

/// The most emotionally loaded moment in the app — grey, never red: this
/// is a fact about arithmetic, not a mistake the student made. Stated
/// once, then immediately pivoted to something achievable.
class _UnreachableCard extends StatelessWidget {
  final TargetProjection projection;
  final GradingScheme scheme;
  final ValueChanged<ClassificationBand> onSetNearestAchievable;

  const _UnreachableCard({
    required this.projection,
    required this.scheme,
    required this.onSetNearestAchievable,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const color = FeasibilityPalette.unreachable;
    final nearest = projection.nearestAchievable;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.14),
                ),
                child: const Icon(Icons.info_outline, size: 24, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Not reachable now',
                      style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Even with a perfect ${_fmt(scheme.maxPoint)} in every '
                      'remaining semester you\'d finish at '
                      '${_fmt(projection.ceilingCgpa)}. '
                      '${projection.targetLabel ?? 'This target'} needs '
                      '${_fmt(projection.targetCgpa)}.',
                      style: const TextStyle(
                        color: OnboardingLightPalette.bodyText,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (nearest != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: OnboardingLightPalette.divider),
            ),
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 20, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${nearest.label} is still open',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final nearestProjection = ProjectionSolver.solveForTarget(
                  standing: AcademicStanding(
                    cgpa: projection.currentCgpa,
                    totalQualityPoints: projection.currentCgpa * projection.creditsEarned,
                    totalCreditUnits: projection.creditsEarned,
                    totalCreditsPassed: projection.creditsEarned,
                  ),
                  scheme: scheme,
                  targetCgpa: nearest.minCgpa,
                  targetLabel: nearest.label,
                  semestersRemaining: projection.semestersRemaining,
                );
                final req = nearestProjection.requiredAverage;
                return Text(
                  req != null
                      ? "You'd need ${_fmt(req)} across your remaining "
                          '${projection.semestersRemaining} semesters.'
                      : 'Your record is already final at this level.',
                  style: const TextStyle(color: OnboardingLightPalette.secondaryText, fontSize: 15),
                );
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: () => onSetNearestAchievable(nearest),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                child: Text(
                  'Set this instead',
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final bool saving;
  final VoidCallback onPressed;
  const _SaveButton({required this.saving, required this.onPressed});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.saving) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = !widget.saving;
    return GestureDetector(
      key: const ValueKey('saveGoalButtonTap'),
      onTap: interactive ? widget.onPressed : null,
      onTapDown: interactive ? (_) => _setPressed(true) : null,
      onTapUp: interactive ? (_) => _setPressed(false) : null,
      onTapCancel: interactive ? () => _setPressed(false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: !_pressed
              ? const LinearGradient(
                  colors: [
                    OnboardingLightPalette.primaryGradientStart,
                    OnboardingLightPalette.primary,
                  ],
                )
              : null,
          color: _pressed ? OnboardingLightPalette.primary : null,
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: OnboardingLightPalette.primary.withValues(alpha: 0.22),
                    blurRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: OnboardingLightPalette.primary.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: OnboardingLightPalette.primary.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: widget.saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Text(
                'Save goal',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

class _TargetPickerSheet extends StatefulWidget {
  final GradingScheme scheme;
  final List<TargetProjection> projections;

  const _TargetPickerSheet({required this.scheme, required this.projections});

  @override
  State<_TargetPickerSheet> createState() => _TargetPickerSheetState();
}

class _TargetPickerSheetState extends State<_TargetPickerSheet> {
  bool _customMode = false;
  final _customController = TextEditingController();
  String? _customError;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _submitCustom() {
    final value = double.tryParse(_customController.text.trim());
    if (value == null || value < 0 || value > widget.scheme.maxPoint) {
      setState(() => _customError = 'Enter a value between 0.00 and '
          '${_fmt(widget.scheme.maxPoint)}');
      return;
    }
    Navigator.of(context).pop(_PickerResult.custom(value));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_customMode) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Custom target CGPA',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _customController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00 – ${_fmt(widget.scheme.maxPoint)}',
                  errorText: _customError,
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: OnboardingLightPalette.searchBorder),
                  ),
                ),
                onSubmitted: (_) => _submitCustom(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _submitCustom,
                  child: const Text('Set target'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Target Classification',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.projections.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: OnboardingLightPalette.divider),
              itemBuilder: (context, i) {
                final p = widget.projections[i];
                final band = widget.scheme.bandsDescending
                    .firstWhere((b) => b.label == p.targetLabel);
                return InkWell(
                  onTap: () => Navigator.of(context).pop(_PickerResult.band(band)),
                  child: SizedBox(
                    height: 60,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              band.label,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            p.requiredAverage != null
                                ? 'needs ${_fmt(p.requiredAverage!)}'
                                : 'already final',
                            style: TextStyle(
                              color: p.feasibility.color,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: OnboardingLightPalette.divider),
          InkWell(
            onTap: () => setState(() => _customMode = true),
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.tune, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Custom target',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

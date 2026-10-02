/// GPA reveal — Act 1, step 4 of 4. The payoff screen, shown BEFORE any
/// account exists.
///
/// The signup gate sits AFTER this screen rather than before it, because by
/// now the student has something real to lose. Every number here must be
/// real too: no cohort ranking (no other student's results exist in this
/// database), no invented percentage average (grades are letters, not
/// scores), no subject-area breakdown (there is no course-to-discipline
/// taxonomy and nothing to break down from one semester), and no
/// "Excellent" label the grading scheme never defined. All figures come
/// from `CgpaEngine.computeSemester` and the active `GradingScheme` — never
/// hardcoded, never computed here.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';
import '../../../shared/widgets/onboarding_header.dart';
import '../providers/onboarding_provider.dart';

String _fmt(double v) => v.toStringAsFixed(2);

/// Drops a trailing ".0" for numbers that land on a whole value (quality
/// points and grade points nearly always do) without hiding real fractions
/// a custom scheme might produce.
String _fmtNum(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// Next semester in sequence — two terms per level, then the level
/// increments (100, 200, 300, ...). Used by "Add another semester" so the
/// student isn't asked to re-pick what they just told the app.
({int level, SemesterTerm term}) _nextSemester(int level, SemesterTerm term) {
  if (term == SemesterTerm.first) {
    return (level: level, term: SemesterTerm.second);
  }
  return (level: level + 100, term: SemesterTerm.first);
}

class GpaRevealScreen extends ConsumerStatefulWidget {
  const GpaRevealScreen({super.key});

  @override
  ConsumerState<GpaRevealScreen> createState() => _GpaRevealScreenState();
}

class _GpaRevealScreenState extends ConsumerState<GpaRevealScreen> {
  bool _checkedPersisted = false;

  @override
  void initState() {
    super.initState();
    // The onboarding draft lives only in memory and does not survive a
    // reload. By the time this screen is reachable, `commitDraft()` has
    // already persisted the semester via `academicRecordProvider` — so on a
    // reload, wait for that reload to finish and fall back to the persisted
    // copy instead of spinning forever on draft state that is gone for good.
    if (ref.read(onboardingDraftProvider).committed != null) {
      _checkedPersisted = true;
    } else {
      ref.read(academicRecordProvider.notifier).ready.then((_) {
        if (mounted) setState(() => _checkedPersisted = true);
      });
    }
  }

  void _goToResults() => context.go(Routes.addFirstResults);

  void _addAnotherSemester(OnboardingDraft draft) {
    final next = _nextSemester(draft.level, draft.term);
    ref
        .read(onboardingDraftProvider.notifier)
        .setSemesterContext(level: next.level, term: next.term);
    context.go(Routes.addFirstResults);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingDraftProvider);
    final record = ref.watch(academicRecordProvider);

    final semester = draft.committed ??
        (record.semesters.isNotEmpty ? record.semesters.last : null);
    final scheme = draft.committed != null ? draft.scheme : record.scheme;

    return Theme(
      data: AppTheme.onboardingLight,
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;

          if (semester == null) {
            if (_checkedPersisted) {
              // Nothing was ever committed, on this boot or a previous
              // one — there is nothing to reveal. Bounce back to entry
              // instead of showing a spinner that will never resolve.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) context.go(Routes.addFirstResults);
              });
            }
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.dark,
              child: Scaffold(
                backgroundColor: colorScheme.surface,
                body: const Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final computation =
              CgpaEngine.computeSemester(semester: semester, scheme: scheme);

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: colorScheme.surface,
              body: SafeArea(
                child: Column(
                  children: [
                    OnboardingHeader(
                      stepNumber: OnboardingStep.yourGpa.stepNumber,
                      totalSteps: OnboardingStep.totalSteps,
                      title: OnboardingStep.yourGpa.title,
                      onBack: _goToResults,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _RevealBody(
                          semester: semester,
                          scheme: scheme,
                          computation: computation,
                          onFixExcluded: _goToResults,
                        ),
                      ),
                    ),
                    _PrimaryFooter(
                      onSave: () => context.go(Routes.signIn),
                      onAddAnother: () => _addAnotherSemester(draft),
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
}

class _RevealBody extends StatelessWidget {
  final Semester semester;
  final GradingScheme scheme;
  final SemesterComputation computation;
  final VoidCallback onFixExcluded;

  const _RevealBody({
    required this.semester,
    required this.scheme,
    required this.computation,
    required this.onFixExcluded,
  });

  @override
  Widget build(BuildContext context) {
    final band = scheme.classify(computation.gpa);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Text(
          "Here's your GPA",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: OnboardingLightPalette.bodyText,
            fontSize: 27,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${semester.results.length} courses · '
          '${computation.creditUnits} credit units',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: OnboardingLightPalette.secondaryText,
            fontSize: 16.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        _HeroCard(
          gpa: computation.gpa,
          scheme: scheme,
          band: band,
          semesterLabel: '${semester.level} Level · ${scheme.termLabel(semester.term)}',
        ),
        const SizedBox(height: 20),
        _StatRow(
          courseCount: semester.results.length,
          creditUnits: computation.creditUnits,
        ),
        const SizedBox(height: 20),
        _CalculationCard(
          scheme: scheme,
          semester: semester,
          computation: computation,
          onFixExcluded: onFixExcluded,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _HeroCard extends StatefulWidget {
  final double gpa;
  final GradingScheme scheme;
  final ClassificationBand? band;
  final String semesterLabel;

  const _HeroCard({
    required this.gpa,
    required this.scheme,
    required this.band,
    required this.semesterLabel,
  });

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  bool _confettiActive = false;

  /// Position among best-first bands: 0 is top, 1 second, etc. Null when
  /// the GPA falls outside every defined band (nothing invented for it).
  int? get _bandIndex {
    final band = widget.band;
    if (band == null) return null;
    final index =
        widget.scheme.bandsDescending.indexWhere((b) => b.label == band.label);
    return index == -1 ? null : index;
  }

  bool get _isTopTwoBand {
    final index = _bandIndex;
    return index != null && index <= 1;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gaugeSize = width < 380 ? 168.0 : 200.0;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final showConfetti = _isTopTwoBand && !reduceMotion;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GpaRevealPalette.heroGradientTop, Colors.white],
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: gaugeSize,
            height: gaugeSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _GpaGauge(
                  gpa: widget.gpa,
                  maxPoint: widget.scheme.maxPoint,
                  size: gaugeSize,
                  onArcComplete: () {
                    if (showConfetti && mounted) {
                      setState(() => _confettiActive = true);
                    }
                  },
                ),
                if (showConfetti)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _Confetti(
                        key: const ValueKey('gpaRevealConfetti'),
                        active: _confettiActive,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.semesterLabel,
            style: const TextStyle(
              color: OnboardingLightPalette.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.band != null) ...[
            const SizedBox(height: 20),
            _ClassificationPill(
              key: const ValueKey('classificationPill'),
              band: widget.band!,
              index: _bandIndex ?? 3,
            ),
          ],
        ],
      ),
    );
  }
}

/// The circular gauge: track, animated gradient fill, and radiating tick
/// marks, all in one [CustomPainter] rather than a package — see the task
/// brief. The digits count up in lockstep with the same eased animation
/// that draws the arc, so they always finish together.
class _GpaGauge extends StatefulWidget {
  final double gpa;
  final double maxPoint;
  final double size;
  final VoidCallback? onArcComplete;

  const _GpaGauge({
    required this.gpa,
    required this.maxPoint,
    required this.size,
    this.onArcComplete,
  });

  @override
  State<_GpaGauge> createState() => _GpaGaugeState();
}

class _GpaGaugeState extends State<_GpaGauge> with TickerProviderStateMixin {
  late final AnimationController _arcController;
  late final Animation<double> _arcValue;
  late final AnimationController _tickController;
  late final Animation<double> _tickOpacity;

  @override
  void initState() {
    super.initState();
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _arcValue = CurvedAnimation(parent: _arcController, curve: Curves.easeOutCubic);
    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tickOpacity = CurvedAnimation(parent: _tickController, curve: Curves.easeOut);

    _arcController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tickController.forward();
        widget.onArcComplete?.call();
      }
    });
    _arcController.forward();
  }

  @override
  void dispose() {
    _arcController.dispose();
    _tickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_arcValue, _tickOpacity]),
      builder: (context, _) {
        final fraction = _arcValue.value;
        final displayed = widget.gpa * fraction;
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(widget.size),
              painter: _GaugePainter(
                fraction: fraction,
                gpa: widget.gpa,
                maxPoint: widget.maxPoint,
                tickOpacity: _tickOpacity.value,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _fmt(displayed),
                  style: const TextStyle(
                    color: OnboardingLightPalette.bodyText,
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Semester GPA',
                  style: TextStyle(
                    color: OnboardingLightPalette.secondaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double fraction;
  final double gpa;
  final double maxPoint;
  final double tickOpacity;

  static const _startDeg = 135.0;
  static const _sweepDeg = 270.0;
  static const _strokeWidth = 14.0;

  _GaugePainter({
    required this.fraction,
    required this.gpa,
    required this.maxPoint,
    required this.tickOpacity,
  });

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const tickAllowance = 12.0 + 14.0; // gap beyond track + tick length
    final trackRadius =
        size.width / 2 - _strokeWidth / 2 - tickAllowance;
    final rect = Rect.fromCircle(center: center, radius: trackRadius);

    final startRad = _rad(_startDeg);
    final fullSweepRad = _rad(_sweepDeg);

    final trackPaint = Paint()
      ..color = OnboardingLightPalette.searchBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawArc(rect, startRad, fullSweepRad, false, trackPaint);

    final progress = maxPoint <= 0 ? 0.0 : (gpa / maxPoint).clamp(0.0, 1.0);
    final sweepNow = fullSweepRad * progress * fraction;

    if (sweepNow > 0.001) {
      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [
            GpaRevealPalette.gaugeGradientLight,
            OnboardingLightPalette.primary,
            GpaRevealPalette.gaugeGradientDark,
          ],
          transform: GradientRotation(0),
        ).createShader(
          Rect.fromCircle(center: center, radius: trackRadius),
          textDirection: TextDirection.ltr,
        );
      canvas.drawArc(rect, startRad, sweepNow, false, fillPaint);
    }

    if (tickOpacity > 0.001) {
      _paintTicks(canvas, center, trackRadius);
    }
  }

  void _paintTicks(Canvas canvas, Offset center, double trackRadius) {
    final tickPaint = Paint()
      ..color = OnboardingLightPalette.primary.withValues(alpha: 0.30 * tickOpacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final innerRadius = trackRadius + _strokeWidth / 2 + 12;
    final outerRadius = innerRadius + 14;

    for (var i = 0; i < 6; i++) {
      // Flanking either side of the bottom opening, fanning further away
      // from the arc's two open ends at 12° increments.
      final rightDeg = 45 - 12 * i;
      final leftDeg = 135 + 12 * i;
      for (final deg in [rightDeg, leftDeg]) {
        final rad = _rad(deg.toDouble());
        final direction = Offset(math.cos(rad), math.sin(rad));
        canvas.drawLine(
          center + direction * innerRadius,
          center + direction * outerRadius,
          tickPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.gpa != gpa ||
      oldDelegate.maxPoint != maxPoint ||
      oldDelegate.tickOpacity != tickOpacity;
}

/// A restrained confetti burst — gated to top-two classification bands by
/// the caller, since celebrating a Third Class result reads as mockery.
class _Confetti extends StatefulWidget {
  final bool active;

  const _Confetti({super.key, required this.active});

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiPiece {
  final double startX; // fraction of width, 0..1
  final double driftX; // px
  final double rotationSpeed;
  final Color color;
  final bool isCircle;

  const _ConfettiPiece({
    required this.startX,
    required this.driftX,
    required this.rotationSpeed,
    required this.color,
    required this.isCircle,
  });
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  static const _colors = [
    OnboardingLightPalette.primary,
    GpaRevealPalette.gaugeGradientLight,
    OnboardingLightPalette.success,
    GpaRevealPalette.confettiAmber,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final random = math.Random(7);
    _pieces = List.generate(14, (i) {
      return _ConfettiPiece(
        startX: random.nextDouble(),
        driftX: (random.nextDouble() - 0.5) * 40,
        rotationSpeed: (random.nextDouble() - 0.5) * 6,
        color: _colors[i % _colors.length],
        isCircle: i.isEven,
      );
    });
    if (widget.active) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _Confetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
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
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _ConfettiPainter(pieces: _pieces, t: _controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double t;

  _ConfettiPainter({required this.pieces, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    const fadeStart = 1000 / 1400; // last 400ms of 1400ms fades out
    final opacity = t <= fadeStart ? 1.0 : (1.0 - (t - fadeStart) / (1 - fadeStart));

    for (final piece in pieces) {
      final dx = piece.startX * size.width + piece.driftX * t;
      final dy = -20 + t * (size.height + 40);
      final rotation = piece.rotationSpeed * t * math.pi;

      final paint = Paint()..color = piece.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rotation);
      if (piece.isCircle) {
        canvas.drawCircle(Offset.zero, 3, paint);
      } else {
        canvas.drawRect(const Rect.fromLTWH(-2, -1, 4, 2), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}

class _ClassificationPill extends StatelessWidget {
  final ClassificationBand band;
  final int index;

  const _ClassificationPill({super.key, required this.band, required this.index});

  Color get _color => ClassificationPalette.colorForBandIndex(index);

  IconData get _icon => index <= 1 ? Icons.arrow_upward : Icons.remove;

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            band.shortLabel,
            style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final int courseCount;
  final int creditUnits;

  const _StatRow({required this.courseCount, required this.creditUnits});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.menu_book_outlined,
              value: '$courseCount',
              label: 'Courses',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.school_outlined,
              value: '$creditUnits',
              label: 'Credit units',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OnboardingLightPalette.standingFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: OnboardingLightPalette.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: OnboardingLightPalette.primary),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: OnboardingLightPalette.bodyText,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: OnboardingLightPalette.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Show the calculation" — replaces the fabricated performance breakdown.
/// A student who can verify the arithmetic will trust the projections
/// later; this is the single most valuable element on the screen.
class _CalculationCard extends StatelessWidget {
  final GradingScheme scheme;
  final Semester semester;
  final SemesterComputation computation;
  final VoidCallback onFixExcluded;

  const _CalculationCard({
    required this.scheme,
    required this.semester,
    required this.computation,
    required this.onFixExcluded,
  });

  @override
  Widget build(BuildContext context) {
    final excludedIds = computation.excluded.map((e) => e.resultId).toSet();
    final counted = semester.results.where((r) => !excludedIds.contains(r.id)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: OnboardingLightPalette.searchBorder, width: 1.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: const ValueKey('calculationExpansionTile'),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  leading: const Icon(
                    Icons.calculate_outlined,
                    size: 20,
                    color: OnboardingLightPalette.primary,
                  ),
                  title: const Text(
                    'How this was calculated',
                    style: TextStyle(
                      color: OnboardingLightPalette.bodyText,
                      fontSize: 17.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    for (final result in counted)
                      _CalculationRow(scheme: scheme, result: result),
                    const Divider(height: 1, color: Color(0xFFECECF1)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: OnboardingLightPalette.bodyText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_fmtNum(computation.qualityPoints)} ÷ ${computation.creditUnits}',
                          style: const TextStyle(
                            color: OnboardingLightPalette.secondaryText,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _fmt(computation.gpa),
                          style: const TextStyle(
                            color: OnboardingLightPalette.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (computation.excluded.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ExcludedBlock(excluded: computation.excluded, onFix: onFixExcluded),
          ],
        ],
      ),
    );
  }
}

class _CalculationRow extends StatelessWidget {
  final GradingScheme scheme;
  final CourseResult result;

  const _CalculationRow({required this.scheme, required this.result});

  @override
  Widget build(BuildContext context) {
    final point = scheme.pointForLetter(result.grade) ?? 0;
    final qualityPoints = point * result.creditUnit;

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFECECF1), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              result.courseCode,
              style: const TextStyle(
                color: OnboardingLightPalette.bodyText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${result.creditUnit} × ${_fmtNum(point)} (${result.grade})',
              textAlign: TextAlign.center,
              style: const TextStyle(color: OnboardingLightPalette.secondaryText, fontSize: 15),
            ),
          ),
          Text(
            _fmtNum(qualityPoints),
            style: const TextStyle(
              color: OnboardingLightPalette.bodyText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A student must always be able to answer "why isn't this course counted?"
/// without contacting support — so every excluded row states the reason and
/// a way back to fix it.
class _ExcludedBlock extends StatelessWidget {
  final List<ExcludedResult> excluded;
  final VoidCallback onFix;

  const _ExcludedBlock({required this.excluded, required this.onFix});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OnboardingLightPalette.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Not counted',
            style: TextStyle(
              color: OnboardingLightPalette.amber,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final e in excluded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${e.courseCode} — ',
                            style: const TextStyle(
                              color: OnboardingLightPalette.bodyText,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: e.reason,
                            style: const TextStyle(
                              color: OnboardingLightPalette.secondaryText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: onFix,
                      child: const Text(
                        'Fix',
                        style: TextStyle(
                          color: OnboardingLightPalette.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

class _PrimaryFooter extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onAddAnother;

  const _PrimaryFooter({required this.onSave, required this.onAddAnother});

  @override
  State<_PrimaryFooter> createState() => _PrimaryFooterState();
}

class _PrimaryFooterState extends State<_PrimaryFooter> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          GestureDetector(
            key: const ValueKey('saveResultButtonTap'),
            onTap: widget.onSave,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: _pressed ? 0.98 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 62,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _pressed ? OnboardingLightPalette.primary : null,
                  gradient: _pressed
                      ? null
                      : const LinearGradient(
                          colors: [
                            OnboardingLightPalette.primaryGradientStart,
                            OnboardingLightPalette.primary,
                          ],
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: OnboardingLightPalette.primary.withValues(alpha: 0.22),
                      blurRadius: _pressed ? 4 : 16,
                      offset: _pressed ? Offset.zero : const Offset(0, 6),
                    ),
                    if (!_pressed)
                      BoxShadow(
                        color: OnboardingLightPalette.primary.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 20, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Save this result',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: TextButton(
              onPressed: widget.onAddAnother,
              child: const Text(
                'Add another semester',
                style: TextStyle(
                  color: OnboardingLightPalette.primary,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.smartphone_outlined, size: 16, color: OnboardingLightPalette.secondaryText),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Saved on this device. Create an account to keep it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: OnboardingLightPalette.secondaryText,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

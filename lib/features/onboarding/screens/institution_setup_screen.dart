/// Institution & scheme setup — step 1 of Act 1.
///
/// Resolves the grading scheme (see AGENTS.md's "four separable concerns")
/// before any result is entered, so `AddFirstResultsScreen`'s grade dropdown
/// is never populated from a guess made with zero institution context.
///
/// Unlike the rest of the app (permanently on `GradientScaffold`'s dark
/// gradient), this screen is genuinely light — see `AppTheme.onboardingLight`
/// / `OnboardingLightPalette`. Do not copy this screen's `Theme` override
/// elsewhere without the same design sign-off.
///
/// **Single-institution mode**: Perform+ is scoped to FUTO only — this
/// screen no longer offers a search/picker over `nigerianInstitutions`, it
/// auto-selects FUTO on entry and shows it centered with a bank icon
/// (`Icons.account_balance`) rather than `LettermarkAvatar`'s real logo
/// asset. `data/seed/nigerian_institutions.dart`'s other fifteen entries are
/// deliberately NOT deleted from that file — they stay fully defined there
/// (and in `defaultSchemes`) in case multi-institution support is restored
/// later; this screen simply never surfaces them. The "Other (Add
/// Manually)" custom-institution flow was removed for the same reason: it
/// contradicts a single-institution product.
///
/// Auto-selecting FUTO here does two independent things: it updates
/// `onboardingDraftProvider` (the session-only draft the rest of Act 1
/// reads) AND writes straight through `gradingSchemeRepositoryProvider` to
/// Drift, so the choice survives an app restart even though the draft
/// itself does not.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/seed/nigerian_institutions.dart';
import '../../../domain/models/grading_scheme.dart';
import '../../../shared/widgets/onboarding_header.dart';
import '../providers/onboarding_provider.dart';

class InstitutionSetupScreen extends ConsumerStatefulWidget {
  const InstitutionSetupScreen({super.key});

  @override
  ConsumerState<InstitutionSetupScreen> createState() =>
      _InstitutionSetupScreenState();
}

class _InstitutionSetupScreenState
    extends ConsumerState<InstitutionSetupScreen> {
  static final Institution _futo =
      nigerianInstitutions.firstWhere((i) => i.id == 'futo');

  String? _selectedInstitutionId;

  @override
  void initState() {
    super.initState();
    // Only one institution is ever offered, so it's selected immediately
    // rather than waiting on a tap that has nothing else to choose between.
    // The provider writes in `_persistSelection` can't run synchronously
    // here -- Riverpod forbids modifying a provider mid-build, which
    // `initState` still counts as -- so they're deferred one frame.
    _selectedInstitutionId = _futo.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _persistSelection(_futo.id);
    });
  }

  String? get _selectedName {
    final id = _selectedInstitutionId;
    if (id == null) return null;
    return nigerianInstitutions.firstWhere((i) => i.id == id).name;
  }

  String? get _selectedAbbreviation {
    final id = _selectedInstitutionId;
    if (id == null) return null;
    return nigerianInstitutions.firstWhere((i) => i.id == id).abbreviation;
  }

  GradingScheme? get _selectedScheme {
    final id = _selectedInstitutionId;
    if (id == null) return null;
    return defaultSchemes[id] ?? fallbackScheme;
  }

  void _persistSelection(String institutionId) {
    final scheme = defaultSchemes[institutionId] ?? fallbackScheme;
    ref.read(onboardingDraftProvider.notifier).setInstitution(institutionId);
    unawaited(
      ref.read(gradingSchemeRepositoryProvider).saveActiveScheme(scheme),
    );
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      SystemNavigator.pop();
    }
  }

  Future<void> _openSchemeSheet(GradingScheme scheme, String label) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OnboardingLightPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Theme(
        data: AppTheme.onboardingLight,
        child: _SchemeDetailSheet(scheme: scheme, label: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.onboardingLight,
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final scheme = _selectedScheme;
          final selectedName = _selectedName;
          final canContinue = _selectedInstitutionId != null;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: colorScheme.surface,
              resizeToAvoidBottomInset: true,
              body: SafeArea(
                child: Column(
                  children: [
                    OnboardingHeader(
                      stepNumber: OnboardingStep.institution.stepNumber,
                      totalSteps: OnboardingStep.totalSteps,
                      title: OnboardingStep.institution.title,
                      onBack: _handleBack,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                      child: Text(
                        'Your University',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minHeight: constraints.maxHeight),
                            child: const Center(child: _FutoHero()),
                          ),
                        ),
                      ),
                    ),
                    _Footer(
                      visible: canContinue,
                      scheme: scheme,
                      selectedName: selectedName,
                      onChangeScheme: scheme == null || selectedName == null
                          ? null
                          : () => _openSchemeSheet(
                                scheme,
                                _selectedAbbreviation ?? selectedName,
                              ),
                      onReviewScheme: scheme == null || selectedName == null
                          ? null
                          : () => _openSchemeSheet(
                                scheme,
                                _selectedAbbreviation ?? selectedName,
                              ),
                      unverifiedAbbreviation:
                          (scheme != null && !scheme.isVerified)
                              ? (_selectedAbbreviation ?? selectedName!)
                              : null,
                      canContinue: canContinue,
                      onContinue: () => context.go(Routes.addFirstResults),
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

/// Perform+'s single supported institution, centered and shown with a
/// generic bank icon rather than `LettermarkAvatar`'s real logo asset —
/// this screen's whole point is "there is only one option here," so it
/// reads as an institutional/official mark rather than a specific brand.
class _FutoHero extends StatelessWidget {
  const _FutoHero();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Icon(
            Icons.account_balance,
            size: 60,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Federal University of Technology, Owerri',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'FUTO',
          style: TextStyle(
            color: OnboardingLightPalette.secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Fixed footer block: grading scheme section (hidden until a selection
/// exists) plus the Continue button. Never scrolls.
class _Footer extends StatelessWidget {
  final bool visible;
  final GradingScheme? scheme;
  final String? selectedName;
  final VoidCallback? onChangeScheme;
  final VoidCallback? onReviewScheme;
  final String? unverifiedAbbreviation;
  final bool canContinue;
  final VoidCallback onContinue;

  const _Footer({
    required this.visible,
    required this.scheme,
    required this.selectedName,
    required this.onChangeScheme,
    required this.onReviewScheme,
    required this.unverifiedAbbreviation,
    required this.canContinue,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: !visible || scheme == null || selectedName == null
                  ? const SizedBox.shrink(key: ValueKey('scheme-hidden'))
                  : Padding(
                      key: const ValueKey('scheme-visible'),
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grading Scheme',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (unverifiedAbbreviation != null) ...[
                            _UnverifiedSchemeBanner(
                              abbreviation: unverifiedAbbreviation!,
                              onReview: onReviewScheme,
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  'Use default scheme for $selectedName',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: OnboardingLightPalette.secondaryText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 44,
                                child: TextButton(
                                  onPressed: onChangeScheme,
                                  child: Text(
                                    'Change',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          _ContinueButton(enabled: canContinue, onPressed: onContinue),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              key: const ValueKey('alreadyHaveAccountTap'),
              onPressed: () => context.go(Routes.signIn),
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14.5, color: OnboardingLightPalette.secondaryText),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Sign in',
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnverifiedSchemeBanner extends StatelessWidget {
  final String abbreviation;
  final VoidCallback? onReview;

  const _UnverifiedSchemeBanner({required this.abbreviation, this.onReview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OnboardingLightPalette.amberBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: OnboardingLightPalette.amber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "We haven't confirmed $abbreviation's exact grading rules "
                  'yet. Check the defaults before you rely on your CGPA.',
                  style: const TextStyle(
                    color: OnboardingLightPalette.amber,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (onReview != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onReview,
                    child: const Text(
                      'Review scheme',
                      style: TextStyle(
                        color: OnboardingLightPalette.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _ContinueButton({required this.enabled, required this.onPressed});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;

    return GestureDetector(
      key: const ValueKey('continueButtonTap'),
      onTap: enabled ? widget.onPressed : null,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.98 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: enabled && !_pressed
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      OnboardingLightPalette.primaryGradientStart,
                      OnboardingLightPalette.primary,
                    ],
                  )
                : null,
            color: !enabled
                ? OnboardingLightPalette.disabledFill
                : (_pressed ? OnboardingLightPalette.primary : null),
            boxShadow: !enabled
                ? null
                : _pressed
                    ? [
                        BoxShadow(
                          color: OnboardingLightPalette.primary
                              .withValues(alpha: 0.22),
                          blurRadius: 4,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: OnboardingLightPalette.primary
                              .withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: OnboardingLightPalette.primary
                              .withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
          ),
          child: Text(
            'Continue',
            style: TextStyle(
              color: enabled ? Colors.white : OnboardingLightPalette.disabledText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only viewer opened by both "Change" and "Review scheme" — there is
/// no scheme editor yet, so this only ever displays what's already resolved.
class _SchemeDetailSheet extends StatelessWidget {
  final GradingScheme scheme;
  final String label;

  const _SchemeDetailSheet({required this.scheme, required this.label});

  static String _policyLabel(RepeatPolicy policy) => switch (policy) {
        RepeatPolicy.replaceOriginal => 'New attempt replaces the original',
        RepeatPolicy.countBothAttempts => 'Both attempts count',
        RepeatPolicy.replaceWithCap => 'New attempt replaces, capped',
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scheme.name,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Max point ${scheme.maxPoint.toStringAsFixed(1)} · '
                '${_policyLabel(scheme.repeatPolicy)}',
                style: const TextStyle(
                  color: OnboardingLightPalette.secondaryText,
                  fontSize: 14,
                ),
              ),
              if (!scheme.isVerified) ...[
                const SizedBox(height: 12),
                _UnverifiedSchemeBanner(abbreviation: label),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Letter grades',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final g in scheme.grades)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${g.letter} — ${g.point} pts '
                            '(${g.minScore}–${g.maxScore})',
                            style: const TextStyle(
                              color: OnboardingLightPalette.bodyText,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Classification bands',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final b in scheme.classifications)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${b.shortLabel} — '
                            '${b.minCgpa.toStringAsFixed(2)}–'
                            '${b.maxCgpa.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: OnboardingLightPalette.bodyText,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared header for the light-themed onboarding/auth screens: back arrow,
/// step badge/title/version pill, progress bar. First used by institution
/// setup, now also by add-results and sign-in — see `AppTheme.onboardingLight`.
///
/// Act 1 and Act 2 each keep their OWN step counter — Act 1 completes at
/// the GPA reveal (bar at 100%), and Act 2 restarts at step 1 rather than
/// continuing the same sequence (auth is a distinct phase). [OnboardingStep]
/// and [AccountSetupStep] each derive their step number/progress fraction
/// from a single enum value so a screen can't show a badge and a bar that
/// disagree; [OnboardingHeader] itself only takes the resulting primitives,
/// so it stays usable by either sequence (or a custom title, as sign-in
/// needs — its title switches with sign-up/sign-in mode rather than being
/// fixed per step).
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// The perceived Act 1 sequence (splash isn't a step).
enum OnboardingStep {
  institution,
  addResults,
  grades,
  yourGpa;

  int get stepNumber => index + 1;
  static int get totalSteps => AppConstants.onboardingSteps.length;
  String get title => AppConstants.onboardingSteps[index];
}

/// Act 2's own sequence — starts back at step 1 after Act 1's GPA reveal.
enum AccountSetupStep {
  account,
  profile,
  backfill,
  goal;

  int get stepNumber => index + 1;
  static const totalSteps = 4;
  String get title => const ['Account', 'Profile', 'Backfill', 'Goal'][index];
}

class OnboardingHeader extends StatelessWidget {
  final int stepNumber;
  final int totalSteps;
  final String title;

  /// Null hides the back arrow entirely (still reserving its 48dp slot, so
  /// the step row/progress bar don't shift) — for a screen with nowhere
  /// useful to go back to, e.g. profile setup right after account creation.
  final VoidCallback? onBack;

  const OnboardingHeader({
    super.key,
    required this.stepNumber,
    required this.totalSteps,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progressFraction = stepNumber / totalSteps;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: onBack == null
                ? null
                : Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onBack,
                      child: Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.primary, width: 1.5),
                ),
                child: Text(
                  'V${AppConstants.version.split('.').first}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  ColoredBox(color: colorScheme.outlineVariant),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progressFraction),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: ColoredBox(color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

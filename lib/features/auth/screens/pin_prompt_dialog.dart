/// The one-time "add a PIN?" nudge shown on the Dashboard once a student
/// has real data to protect, not before. Dismissing (either button, or the
/// barrier) marks `pinProvider`'s `promptDismissed` so it never nags again
/// — the PIN itself stays reachable any time from Me/the drawer's "More
/// settings", so declining here isn't the only chance to set one up.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/pin_provider.dart';
import 'pin_setup_sheet.dart';

Future<void> showPinPromptDialog(BuildContext context, WidgetRef ref) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.lock_outline_rounded, color: Theme.of(dialogContext).colorScheme.primary),
      title: const Text('Add a PIN for extra security?'),
      content: const Text(
        'A 4-digit PIN keeps your academic record private if someone else picks up your phone.',
        style: TextStyle(color: OnboardingLightPalette.secondaryText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Maybe later'),
        ),
        FilledButton(
          key: const ValueKey('pinPromptSetUpTap'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Set up PIN'),
        ),
      ],
    ),
  );

  await ref.read(pinProvider.notifier).dismissPrompt();
  if (accepted == true && context.mounted) {
    await showPinSetupSheet(context);
  }
}

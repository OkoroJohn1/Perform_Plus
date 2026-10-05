/// The one-time "add recovery questions" nudge — mirrors
/// `pin_prompt_dialog.dart` exactly, shown once a student already has a PIN
/// set but hasn't set up security questions yet (covers both an existing
/// user opening the app right after this update ships, and a student who
/// adds a PIN for the first time and skips straight past this the first
/// time it's offered). Dismissing marks `securityQuestionsProvider`'s
/// `promptDismissed` so it never nags again -- reachable any time after
/// from Me > App lock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../providers/security_questions_provider.dart';
import 'security_questions_setup_sheet.dart';

Future<void> showSecurityQuestionsPromptDialog(BuildContext context, WidgetRef ref) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.quiz_outlined, color: Theme.of(dialogContext).colorScheme.primary),
      title: const Text('Add recovery questions?'),
      content: Text(
        "If you ever forget your PIN and fingerprint isn't available, security questions get you back in.",
        style: TextStyle(color: context.palette.secondaryText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Maybe later'),
        ),
        FilledButton(
          key: const ValueKey('securityQuestionsPromptSetUpTap'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Set up'),
        ),
      ],
    ),
  );

  await ref.read(securityQuestionsProvider.notifier).dismissPrompt();
  if (accepted == true && context.mounted) {
    await showSecurityQuestionsSetupSheet(context);
  }
}

/// The two-tier sign-out confirmation shared by the Me tab and the
/// settings screen's Destructive section -- a single implementation so the
/// two entry points can never drift apart. The first dialog offers an
/// unchecked "also remove my data" box; only checking it AND confirming a
/// second, fully-named dialog actually deletes anything. A plain sign-out
/// always leaves local data untouched, since there is no remote copy of a
/// student's results to recover it from yet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_provider.dart';

void confirmSignOut(
  BuildContext context,
  WidgetRef ref, {
  required AcademicRecord record,
  required int noteCount,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      var removeData = false;
      return StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Sign out?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You can sign back in any time.'),
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const ValueKey('removeDataOnSignOutCheckbox'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: removeData,
                title: const Text('Also remove my data from this device', style: TextStyle(fontSize: 13.5)),
                onChanged: (v) => setState(() => removeData = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('signOutConfirmTap'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (removeData) {
                  confirmDestructiveSignOut(context, ref, record: record, noteCount: noteCount);
                } else {
                  ref.read(authStateProvider.notifier).signOut();
                }
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      );
    },
  );
}

void confirmDestructiveSignOut(
  BuildContext context,
  WidgetRef ref, {
  required AcademicRecord record,
  required int noteCount,
}) {
  final semesterCount = record.semesters.length;
  final resultCount = record.semesters.fold<int>(0, (sum, s) => sum + s.results.length);

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remove your data?'),
      content: Text(
        'This deletes $semesterCount semester${semesterCount == 1 ? '' : 's'}, '
        '$resultCount result${resultCount == 1 ? '' : 's'} and '
        '$noteCount note${noteCount == 1 ? '' : 's'} from this device. '
        "This can't be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('destructiveSignOutConfirmTap'),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            await ref.read(appDatabaseProvider).wipeLocalData(AppConstants.localProfileId);
            await ref.read(authStateProvider.notifier).signOut();
          },
          child: const Text('Delete and sign out'),
        ),
      ],
    ),
  );
}

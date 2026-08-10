/// Profile setup.
///
/// Collects Current Level PLUS entry year and expected graduation year —
/// the engine needs both to know how many semesters remain, which every
/// projection depends on. Derived from the reg number prefix
/// (21/ENG/... -> 2021) via [deriveEntryYear] and always overridable.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/seed/nigerian_institutions.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_form.dart';

class ProfileSetupScreen extends ConsumerWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institutionId = ref.watch(onboardingDraftProvider).institutionId;
    final institution =
        nigerianInstitutions.where((i) => i.id == institutionId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ProfileForm(
            institution: institution,
            onSave: (profile) {
              ref.read(studentProfileProvider.notifier).state = profile;
              ref.read(authStateProvider.notifier).markProfileComplete();
              context.go(Routes.backfill);
            },
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

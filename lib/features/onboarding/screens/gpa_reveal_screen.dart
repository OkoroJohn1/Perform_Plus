/// GPA reveal — the Act 1 payoff.
///
/// This screen is why the signup gate sits AFTER it rather than before.
/// The student now has something to lose, which converts far better than
/// a toll gate placed in front of an unproven promise.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../domain/engine/cgpa_engine.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../providers/onboarding_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(onboardingDraftProvider);
    final record = ref.watch(academicRecordProvider);

    final semester = draft.committed ??
        (record.semesters.isNotEmpty ? record.semesters.last : null);
    final scheme = draft.committed != null ? draft.scheme : record.scheme;

    if (semester == null) {
      if (_checkedPersisted) {
        // Nothing was ever committed, on this boot or a previous one —
        // there is nothing to review. Bounce back to entry instead of
        // showing a spinner that will never resolve.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(Routes.addFirstResults);
        });
      }
      return const GradientScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final computation = CgpaEngine.computeSemester(
      semester: semester,
      scheme: scheme,
    );

    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Your ${computation.shortLabel} GPA',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.14),
                      theme.colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Text(
                  computation.gpa.toStringAsFixed(2),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${computation.creditUnits} credit units  |  '
                '${computation.qualityPoints.toStringAsFixed(0)} quality points',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // "Show the math" builds trust in the number. A student who
              // can verify the calculation will trust the projections later.
              ExpansionTile(
                title: const Text('Show the calculation'),
                tilePadding: EdgeInsets.zero,
                children: [
                  ...semester.results.map((r) {
                    final point = scheme.pointForLetter(r.grade) ?? 0;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(r.courseCode),
                      subtitle: Text(
                        '${r.creditUnit} units x $point (${r.grade})',
                      ),
                      trailing: Text(
                        (point * r.creditUnit).toStringAsFixed(0),
                        style: theme.textTheme.titleSmall,
                      ),
                    );
                  }),
                  const Divider(),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Total'),
                    subtitle: Text(
                      '${computation.qualityPoints.toStringAsFixed(0)} / '
                      '${computation.creditUnits}',
                    ),
                    trailing: Text(
                      computation.gpa.toStringAsFixed(2),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),

              if (computation.excluded.isNotEmpty) ...[
                const SizedBox(height: 8),
                GlassCard(
                  tint: theme.colorScheme.error,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Not counted',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      ...computation.excluded.map((e) => Text(
                            '${e.courseCode} — ${e.reason}',
                            style: theme.textTheme.bodySmall,
                          )),
                    ],
                  ),
                ),
              ],

              const Spacer(),
              GradientButton(
                onPressed: () => context.go(Routes.signIn),
                child: const Text('Save this and track my CGPA'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(Routes.addFirstResults),
                child: const Text('Add another semester first'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

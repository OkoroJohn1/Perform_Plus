import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/seed/nigerian_institutions.dart';
import '../providers/onboarding_provider.dart';

/// Institution and grading scheme setup.
///
/// This resolves FOUR independent things that are commonly conflated:
/// score->letter boundaries, letter->point mapping, classification bands,
/// and repeat/carryover policy. The last one is where calculations silently
/// go wrong for any student with a carryover.
class InstitutionSetupScreen extends ConsumerStatefulWidget {
  const InstitutionSetupScreen({super.key});

  @override
  ConsumerState<InstitutionSetupScreen> createState() =>
      _InstitutionSetupScreenState();
}

class _InstitutionSetupScreenState
    extends ConsumerState<InstitutionSetupScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);

    final results = _query.trim().isEmpty
        ? nigerianInstitutions
        : nigerianInstitutions.where((inst) {
            final q = _query.trim().toLowerCase();
            return inst.name.toLowerCase().contains(q) ||
                inst.abbreviation.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Select your university')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search university...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, i) {
                final inst = results[i];
                final selected = inst.id == draft.institutionId;
                return ListTile(
                  onTap: () => notifier.setInstitution(inst.id),
                  leading: CircleAvatar(
                    backgroundColor: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.account_balance_outlined,
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(inst.name),
                  subtitle: Text(
                    selected
                        ? draft.scheme.name
                        : (inst.state.isEmpty
                            ? 'Enter your own scale'
                            : inst.state),
                  ),
                  trailing: selected
                      ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                      : const Icon(Icons.chevron_right),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Grading scheme'),
                    subtitle: Text(
                      '${draft.scheme.maxPoint} scale  |  '
                      'repeats: ${draft.scheme.repeatPolicy.name}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO(v1): custom scheme editor.
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go(Routes.signIn),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can change this later in Settings.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

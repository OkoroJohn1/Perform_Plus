/// "Set up security questions" flow — pick three DISTINCT questions from
/// the fixed bank (`domain/models/security_question.dart`) and answer each.
/// Reused for both first-time setup and editing later from Me > App lock;
/// either way this simply overwrites whatever was stored before (Supabase
/// `upsert`), since a student revising an answer they'll actually remember
/// is strictly better than a stale one from first setup.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/models/security_question.dart';
import '../providers/security_questions_provider.dart';

Future<void> showSecurityQuestionsSetupSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _SecurityQuestionsSetupSheet(),
  );
}

class _SecurityQuestionsSetupSheet extends ConsumerStatefulWidget {
  const _SecurityQuestionsSetupSheet();

  @override
  ConsumerState<_SecurityQuestionsSetupSheet> createState() => _SecurityQuestionsSetupSheetState();
}

class _SecurityQuestionsSetupSheetState extends ConsumerState<_SecurityQuestionsSetupSheet> {
  final _selected = List<String?>.filled(securityQuestionCount, null);
  final _answerControllers = List.generate(securityQuestionCount, (_) => TextEditingController());
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < securityQuestionCount; i++) {
      _selected[i] = securityQuestionBank[i];
    }
  }

  @override
  void dispose() {
    for (final c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final questions = _selected.cast<String>();
    if (questions.toSet().length != securityQuestionCount) {
      setState(() => _error = 'Choose three different questions.');
      return;
    }
    final answers = _answerControllers.map((c) => c.text.trim()).toList();
    if (answers.any((a) => a.isEmpty)) {
      setState(() => _error = 'Answer every question.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(securityQuestionsProvider.notifier).save(questions, answers);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Security questions saved.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = "Couldn't save right now — check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.quiz_outlined, size: 28, color: palette.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Security questions',
                    style: TextStyle(color: palette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "If you ever forget your PIN and fingerprint isn't available, these get you back in.",
              style: TextStyle(color: palette.secondaryText, fontSize: 13.5),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < securityQuestionCount; i++) ...[
              DropdownButtonFormField<String>(
                initialValue: _selected[i],
                isExpanded: true,
                decoration: InputDecoration(labelText: 'Question ${i + 1}'),
                items: [
                  for (final q in securityQuestionBank)
                    DropdownMenuItem(value: q, child: Text(q, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _selected[i] = v),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _answerControllers[i],
                decoration: const InputDecoration(labelText: 'Your answer'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
            ],
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: palette.error, fontSize: 13)),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

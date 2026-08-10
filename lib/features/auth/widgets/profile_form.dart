/// Shared profile form — used by both Act 2's profile-setup screen and the
/// Me tab's "Edit Profile" entry point, so the six fields are defined once.
///
/// Entry year and expected graduation year are REQUIRED, not cosmetic: the
/// engine needs both to know how many semesters remain, which every
/// projection depends on (see [semestersRemainingFor]).
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/reg_number.dart';
import '../../../data/seed/nigerian_institutions.dart';
import '../providers/profile_provider.dart';

class ProfileForm extends StatefulWidget {
  final StudentProfile? initial;
  final Institution? institution;
  final ValueChanged<StudentProfile> onSave;
  final String saveLabel;

  const ProfileForm({
    super.key,
    this.initial,
    this.institution,
    required this.onSave,
    this.saveLabel = 'Continue',
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final _nameController =
      TextEditingController(text: widget.initial?.fullName ?? '');
  late final _regNumberController =
      TextEditingController(text: widget.initial?.regNumber ?? '');
  late final _departmentController =
      TextEditingController(text: widget.initial?.department ?? '');
  late int _currentLevel = widget.initial?.currentLevel ?? AppConstants.levels.first;
  late int? _entryYear = widget.initial?.entryYear;
  late int? _gradYear = widget.initial?.expectedGraduationYear;

  @override
  void dispose() {
    _nameController.dispose();
    _regNumberController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _onRegNumberChanged(String value) {
    if (_entryYear != null) return; // don't override a value already set
    final derived = deriveEntryYear(value);
    if (derived != null) setState(() => _entryYear = derived);
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _regNumberController.text.trim().isNotEmpty &&
      _departmentController.text.trim().isNotEmpty &&
      _entryYear != null &&
      _gradYear != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final faculties = widget.institution?.faculties ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              _nameController.text.trim().isEmpty
                  ? '?'
                  : _nameController.text.trim()[0].toUpperCase(),
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full Name'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regNumberController,
          decoration: const InputDecoration(labelText: 'Reg. Number'),
          onChanged: (v) {
            _onRegNumberChanged(v);
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        if (faculties.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: faculties.contains(_departmentController.text)
                ? _departmentController.text
                : null,
            decoration: const InputDecoration(labelText: 'Department'),
            items: faculties
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
            onChanged: (v) => setState(() => _departmentController.text = v ?? ''),
          )
        else
          TextField(
            controller: _departmentController,
            decoration: const InputDecoration(labelText: 'Department'),
            onChanged: (_) => setState(() {}),
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _currentLevel,
          decoration: const InputDecoration(labelText: 'Current Level'),
          items: AppConstants.levels
              .map((l) => DropdownMenuItem(value: l, child: Text('$l Level')))
              .toList(),
          onChanged: (v) => setState(() => _currentLevel = v ?? _currentLevel),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: ValueKey('entry-$_entryYear'),
                controller: TextEditingController(text: _entryYear?.toString() ?? ''),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Entry Year'),
                onChanged: (v) => setState(() => _entryYear = int.tryParse(v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: ValueKey('grad-$_gradYear'),
                controller: TextEditingController(text: _gradYear?.toString() ?? ''),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Expected Graduation Year'),
                onChanged: (v) => setState(() => _gradYear = int.tryParse(v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _canSave
              ? () => widget.onSave(
                    StudentProfile(
                      fullName: _nameController.text.trim(),
                      regNumber: _regNumberController.text.trim(),
                      department: _departmentController.text.trim(),
                      currentLevel: _currentLevel,
                      entryYear: _entryYear!,
                      expectedGraduationYear: _gradYear!,
                    ),
                  )
              : null,
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}

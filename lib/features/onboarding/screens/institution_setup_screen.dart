/// Institution & scheme setup — step 1 of Act 1, restored.
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
/// Selecting an institution here does two independent things: it updates
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
import '../widgets/lettermark_avatar.dart';

const _rowHeight = 74.0;
const _dividerIndent = 78.0;

/// Diacritic folding for search — none of the sixteen seeded names actually
/// carry one, but a custom "Other" entry might, and the spec calls for
/// diacritic-insensitive matching regardless.
const _diacritics = 'àáâãäåèéêëìíîïòóôõöùúûüñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÑÇ';
const _asciiFold = 'aaaaaaeeeeiiiiooooouuuuncAAAAAAEEEEIIIIOOOOOUUUUNC';

String _normalizeForSearch(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final idx = _diacritics.indexOf(ch);
    buffer.write(idx == -1 ? ch : _asciiFold[idx]);
  }
  return buffer.toString().toLowerCase();
}

class InstitutionSetupScreen extends ConsumerStatefulWidget {
  const InstitutionSetupScreen({super.key});

  @override
  ConsumerState<InstitutionSetupScreen> createState() =>
      _InstitutionSetupScreenState();
}

class _InstitutionSetupScreenState
    extends ConsumerState<InstitutionSetupScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String _query = '';
  bool _searchFocused = false;
  String? _selectedInstitutionId;
  String? _customInstitutionName;
  bool _madeSelectionThisSession = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Institution> get _filtered {
    final q = _normalizeForSearch(_query.trim());
    if (q.isEmpty) return nigerianInstitutions;
    return nigerianInstitutions
        .where((i) =>
            _normalizeForSearch(i.name).contains(q) ||
            _normalizeForSearch(i.abbreviation).contains(q))
        .toList();
  }

  String? get _selectedName {
    final id = _selectedInstitutionId;
    if (id == null) return null;
    if (id == 'custom') return _customInstitutionName;
    return nigerianInstitutions.firstWhere((i) => i.id == id).name;
  }

  String? get _selectedAbbreviation {
    final id = _selectedInstitutionId;
    if (id == null) return null;
    if (id == 'custom') return 'CUSTOM';
    return nigerianInstitutions.firstWhere((i) => i.id == id).abbreviation;
  }

  GradingScheme? get _selectedScheme {
    final id = _selectedInstitutionId;
    if (id == null) return null;
    return defaultSchemes[id] ?? fallbackScheme;
  }

  void _selectInstitution(Institution institution) {
    setState(() {
      _selectedInstitutionId = institution.id;
      _madeSelectionThisSession = true;
    });
    _persistSelection(institution.id);
  }

  void _selectCustom(String name) {
    setState(() {
      _selectedInstitutionId = 'custom';
      _customInstitutionName = name;
      _madeSelectionThisSession = true;
    });
    _persistSelection('custom');
  }

  void _persistSelection(String institutionId) {
    final scheme = defaultSchemes[institutionId] ?? fallbackScheme;
    ref.read(onboardingDraftProvider.notifier).setInstitution(institutionId);
    unawaited(
      ref.read(gradingSchemeRepositoryProvider).saveActiveScheme(scheme),
    );
  }

  Future<void> _handleBack() async {
    if (_madeSelectionThisSession) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Discard your selection?'),
          content: const Text(
            "You chose an institution but haven't continued yet. Leaving "
            'now discards it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      SystemNavigator.pop();
    }
  }

  Future<void> _openCustomSheet({String? initialName}) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OnboardingLightPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Theme(
        data: AppTheme.onboardingLight,
        child: _CustomInstitutionSheet(initialName: initialName ?? ''),
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      _selectCustom(name.trim());
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        OnboardingHeader(
                          stepNumber: OnboardingStep.institution.stepNumber,
                          totalSteps: OnboardingStep.totalSteps,
                          title: OnboardingStep.institution.title,
                          onBack: _handleBack,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Your University',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _SearchField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                focused: _searchFocused,
                                onClear: () => _searchController.clear(),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _InstitutionList(
                            institutions: _filtered,
                            query: _query,
                            selectedId: _selectedInstitutionId,
                            onSelect: _selectInstitution,
                            onOtherTap: () =>
                                _openCustomSheet(initialName: _query.trim()),
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
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              focused ? colorScheme.primary : OnboardingLightPalette.searchBorder,
          width: focused ? 1.8 : 1.2,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          const Icon(Icons.search,
              size: 22, color: OnboardingLightPalette.hintText),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Search university…',
                hintStyle: TextStyle(
                  color: OnboardingLightPalette.hintText,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox(width: 12);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: OnboardingLightPalette.hintText,
                    ),
                    onPressed: onClear,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Scrollable institution list — the only part of the screen that scrolls.
/// "Other (Add Manually)" is always the last item, even when [institutions]
/// (already filtered by the parent) is empty.
class _InstitutionList extends StatelessWidget {
  final List<Institution> institutions;
  final String query;
  final String? selectedId;
  final ValueChanged<Institution> onSelect;
  final VoidCallback onOtherTap;

  const _InstitutionList({
    required this.institutions,
    required this.query,
    required this.selectedId,
    required this.onSelect,
    required this.onOtherTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = institutions.isEmpty;
    final itemCount = (isEmpty ? 1 : institutions.length) + 1;

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      separatorBuilder: (context, i) {
        if (isEmpty && i == 0) return const SizedBox.shrink();
        return const Divider(
          height: 1,
          thickness: 1,
          indent: _dividerIndent,
          color: OnboardingLightPalette.divider,
        );
      },
      itemBuilder: (context, i) {
        if (isEmpty) {
          if (i == 0) {
            return _EmptyResults(
                query: query.trim(), onAddManually: onOtherTap);
          }
          return _OtherRow(selected: selectedId == 'custom', onTap: onOtherTap);
        }
        if (i == institutions.length) {
          return _OtherRow(selected: selectedId == 'custom', onTap: onOtherTap);
        }
        final institution = institutions[i];
        return _InstitutionRow(
          institution: institution,
          selected: selectedId == institution.id,
          onTap: () => onSelect(institution),
        );
      },
    );
  }
}

class _InstitutionRow extends StatelessWidget {
  final Institution institution;
  final bool selected;
  final VoidCallback onTap;

  const _InstitutionRow({
    required this.institution,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color =
        OnboardingLightPalette.avatarPalette[institution.avatarColorIndex % 8];

    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.symmetric(horizontal: selected ? 12 : 0),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    LettermarkAvatar(
                      abbreviation: institution.abbreviation,
                      color: color,
                      logoAsset: institution.logoAsset,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16.5,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        child: Text(
                          institution.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 22,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: selected ? 1 : 0,
                        child: Icon(
                          Icons.check_circle,
                          size: 22,
                          color: colorScheme.primary,
                        ),
                      ),
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

class _OtherRow extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _OtherRow({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.symmetric(horizontal: selected ? 12 : 0),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(alpha: 0.1),
                      ),
                      child:
                          Icon(Icons.add, size: 22, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        'Other (Add Manually)',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 22,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: selected ? 1 : 0,
                        child: Icon(
                          Icons.check_circle,
                          size: 22,
                          color: colorScheme.primary,
                        ),
                      ),
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

class _EmptyResults extends StatelessWidget {
  final String query;
  final VoidCallback onAddManually;

  const _EmptyResults({required this.query, required this.onAddManually});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 40,
              color: OnboardingLightPalette.emptyIcon,
            ),
            const SizedBox(height: 12),
            Text(
              "No match for '$query'",
              style: const TextStyle(
                color: OnboardingLightPalette.secondaryText,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onAddManually,
              child: Text(
                'Add it manually',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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

/// Bottom sheet for the "Other (Add Manually)" row: a name plus a starting
/// scheme. Building a full custom scheme editor (letter/point mapping,
/// classification bands) is out of scope here — the student starts on
/// [fallbackScheme] (the standard 5.0 scale) and can fine-tune later from
/// the Grading Scheme section's "Change" action.
class _CustomInstitutionSheet extends StatefulWidget {
  final String initialName;

  const _CustomInstitutionSheet({required this.initialName});

  @override
  State<_CustomInstitutionSheet> createState() =>
      _CustomInstitutionSheetState();
}

class _CustomInstitutionSheetState extends State<_CustomInstitutionSheet> {
  late final _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add your institution',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll start you on the standard 5.0 scale — fine-tune it any "
            "time from the Grading Scheme section's Change action.",
            style: TextStyle(
              color: OnboardingLightPalette.secondaryText,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Institution name',
              hintStyle: const TextStyle(color: OnboardingLightPalette.hintText),
              filled: true,
              fillColor: colorScheme.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: OnboardingLightPalette.searchBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => _ContinueButton(
              enabled: value.text.trim().isNotEmpty,
              onPressed: () => Navigator.of(context).pop(_controller.text),
            ),
          ),
        ],
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

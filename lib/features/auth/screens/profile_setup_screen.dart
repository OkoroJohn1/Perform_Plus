/// Profile setup — Act 2 step 2 of 4.
///
/// Entry year and expected graduation are collected here, not as cosmetic
/// extras: `ProjectionSolver` cannot compute a required average without
/// `semestersRemaining`, and that number depends on both years plus current
/// level, not level alone — a 300L Engineering student and a 300L Computer
/// Science student can have different runway. Skip either field and the
/// goal screen, roadmap, and every feasibility calculation downstream are
/// silently broken.
///
/// Writes local Drift first (the screen must complete with zero
/// connectivity), then best-effort mirrors to Supabase via
/// `ProfileRemoteSync.updateProfile` — UPDATE only, never insert, since the
/// `profiles` row already exists via the database trigger on `auth.users`
/// insert. See `profile_remote_sync.dart` for why `faculty` and the photo
/// are NOT part of that remote payload yet.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/reg_number.dart';
import '../../../data/local/profile_photo_store.dart';
import '../../../data/repositories/academic_record_provider.dart';
import '../../../data/seed/nigerian_institutions.dart';
import '../../../shared/widgets/onboarding_header.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// A short, generic fallback list for institutions with no catalogued
/// faculty/department structure (everything except FUTO — see
/// `data/seed/nigerian_institutions.dart`). Suggestions only, never a
/// claim that these are *this* institution's actual departments.
const _commonNigerianDepartments = <String>[
  'Accounting',
  'Banking and Finance',
  'Biochemistry',
  'Business Administration',
  'Chemistry',
  'Civil Engineering',
  'Computer Science',
  'Economics',
  'Electrical/Electronic Engineering',
  'English Language',
  'Law',
  'Mass Communication',
  'Mathematics',
  'Mechanical Engineering',
  'Medicine and Surgery',
  'Microbiology',
  'Nursing Science',
  'Physics',
  'Political Science',
  'Sociology',
];

const _saveTimeout = Duration(seconds: 15);

class ProfileSetupScreen extends ConsumerStatefulWidget {
  /// True when reached from the Me tab's "Edit" button rather than the Act
  /// 2 onboarding flow — shows a back arrow instead of none, and returns to
  /// the caller on save instead of continuing on to Backfill.
  final bool isEditMode;

  const ProfileSetupScreen({super.key, this.isEditMode = false});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _departmentController = TextEditingController();
  final _facultyController = TextEditingController();
  final _nameFocus = FocusNode();

  String? _photoPath;
  String? _faculty;
  int _currentLevel = AppConstants.levels.first;
  int? _entryYear;
  int? _gradYear;
  bool _gradYearManuallySet = false;
  bool _nameTouched = false;
  bool _saving = false;

  Institution? get _institution {
    final id = ref.read(onboardingDraftProvider).institutionId;
    return nigerianInstitutions.where((i) => i.id == id).firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_prefillFromExistingProfile());
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && mounted) setState(() => _nameTouched = true);
    });
    // Sign-up always lands here (never edit mode) -- the natural, earliest
    // point to offer reattaching data orphaned by a deleted account, before
    // Backfill even runs (so a reattach there is picked up immediately
    // instead of the student re-entering results that already exist).
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferDataAttach());
    unawaited(_retrieveLostPhotoIfAny());
  }

  /// Awaits `studentProfileProvider`'s own cold-start Drift read
  /// (`ProfileController.ready`) before reading it -- a plain synchronous
  /// `ref.read` right here on a fresh app start could otherwise race that
  /// async load and see `null` even though a real profile row exists,
  /// rendering this screen blank and letting the student unknowingly
  /// overwrite their real data by saving over it.
  Future<void> _prefillFromExistingProfile() async {
    await ref.read(studentProfileProvider.notifier).ready;
    if (!mounted) return;
    final existing = ref.read(studentProfileProvider);
    if (existing == null) return;
    setState(() {
      _nameController.text = existing.fullName;
      _regNumberController.text = existing.regNumber;
      _departmentController.text = existing.department;
      _faculty = existing.faculty;
      _facultyController.text = existing.faculty ?? '';
      // A saved profile's level isn't guaranteed to still be one of
      // AppConstants.levels (e.g. a corrupted/legacy row) -- the Current
      // Level dropdown's `value` must be among its own `items` or it trips
      // the same "exactly one item with this value" assertion the year
      // dropdowns had (see `_entryYearOptions`'s doc comment above).
      _currentLevel = AppConstants.levels.contains(existing.currentLevel)
          ? existing.currentLevel
          : AppConstants.levels.first;
      _entryYear = existing.entryYear;
      _gradYear = existing.expectedGraduationYear;
      _gradYearManuallySet = true;
      _photoPath = existing.photoPath;
    });
  }

  /// Recovers a photo the system camera picked but this screen's own
  /// `pickImage()` future never got to see -- see
  /// `retrieveLostProfilePhotoBytes`'s doc comment for when that happens.
  Future<void> _retrieveLostPhotoIfAny() async {
    final bytes = await retrieveLostProfilePhotoBytes();
    if (bytes == null || !mounted) return;
    try {
      final processed = processProfilePhoto(bytes);
      final path = await saveProfilePhoto(processed);
      if (!mounted) return;
      setState(() => _photoPath = path);
    } catch (_) {
      // Best-effort -- if processing the recovered bytes fails, the
      // student can just retake the photo.
    }
  }

  Future<void> _maybeOfferDataAttach() async {
    if (!mounted) return;
    final orphanedUid = ref.read(pendingLocalDataAttachProvider);
    if (orphanedUid == null) return;

    final attach = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Existing results found'),
        content: const Text(
          'We found academic results already saved on this device from a '
          'previous account. Attach them to this new account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Attach'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (attach == true) {
      await ref.read(authStateProvider.notifier).attachOrphanedLocalData();
      if (!mounted) return;
      await ref.read(academicRecordProvider.notifier).refresh();
    } else {
      ref.read(authStateProvider.notifier).dismissOrphanedLocalDataOffer();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNumberController.dispose();
    _departmentController.dispose();
    _facultyController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  RegNumberFormat get _regFormat =>
      _institution?.regNumberFormat ?? genericRegNumberFormat;

  bool get _hasKnownFaculties => (_institution?.faculties ?? const []).isNotEmpty;

  List<String> get _departmentOptions {
    final byFaculty = _institution?.departmentsByFaculty ?? const {};
    if (byFaculty.isEmpty) return const [];
    if (_faculty == null) return const [];
    return byFaculty[_faculty] ?? const [];
  }

  void _onRegNumberChanged(String value) {
    if (_entryYear != null) return; // never override a value already set
    final derived = _regFormat.extractEntryYear(value);
    final minYear = DateTime.now().year - 10;
    final maxYear = DateTime.now().year;
    if (derived != null && derived >= minYear && derived <= maxYear) {
      setState(() {
        _entryYear = derived;
        _recomputeGradYearDefault();
      });
    } else {
      setState(() {});
    }
  }

  void _recomputeGradYearDefault() {
    if (_gradYearManuallySet || _entryYear == null) return;
    final programmeYears = (_institution?.maxLevel ?? 500) ~/ 100;
    _gradYear = _entryYear! + programmeYears;
  }

  void _setEntryYear(int? year) {
    setState(() {
      _entryYear = year;
      _recomputeGradYearDefault();
    });
  }

  void _setGradYear(int? year) {
    setState(() {
      _gradYear = year;
      _gradYearManuallySet = true;
    });
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _regNumberController.text.trim().isNotEmpty &&
      _departmentController.text.trim().isNotEmpty &&
      (!_hasKnownFaculties || (_faculty != null && _faculty!.isNotEmpty)) &&
      _entryYear != null &&
      _gradYear != null &&
      _gradYear! > _entryYear!;

  Future<void> _openPhotoSheet() async {
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      backgroundColor: context.palette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Theme(
        data: AppTheme.onboardingLight,
        child: _PhotoSourceSheet(hasPhoto: _photoPath != null),
      ),
    );
    if (action == null) return;
    switch (action) {
      case _PhotoAction.remove:
        final old = _photoPath;
        setState(() => _photoPath = null);
        if (old != null) unawaited(deleteProfilePhotoFile(old));
      case _PhotoAction.camera:
        await _pickAndProcess(ImageSource.camera);
      case _PhotoAction.gallery:
        await _pickAndProcess(ImageSource.gallery);
    }
  }

  Future<void> _pickAndProcess(ImageSource source) async {
    try {
      final bytes = await pickProfilePhotoBytes(source);
      if (bytes == null) return;
      final processed = processProfilePhoto(bytes);
      final path = await saveProfilePhoto(processed);
      if (!mounted) return;
      setState(() => _photoPath = path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't access your camera or photos. You can add a profile "
            'photo later from Settings.',
          ),
        ),
      );
    }
  }

  Future<void> _handleContinue() async {
    setState(() => _saving = true);
    final profile = StudentProfile(
      fullName: _nameController.text.trim(),
      regNumber: _regNumberController.text.trim(),
      department: _departmentController.text.trim(),
      currentLevel: _currentLevel,
      entryYear: _entryYear!,
      expectedGraduationYear: _gradYear!,
      faculty: _faculty?.isNotEmpty == true ? _faculty : null,
      photoPath: _photoPath,
    );
    try {
      await ref
          .read(studentProfileProvider.notifier)
          .save(profile)
          .timeout(_saveTimeout);
      ref.read(authStateProvider.notifier).markProfileComplete();
      if (!mounted) return;
      if (widget.isEditMode) {
        context.pop();
      } else {
        context.go(Routes.backfill);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your profile. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final institution = _institution;

    // Onboarding (not yet signed in, no accent chosen yet) stays fixed on
    // the blue `onboardingLight` theme, same as every other pre-auth
    // screen. Edit mode is reached from the Me tab, AFTER the student has
    // already picked a theme/accent -- forcing `onboardingLight` there too
    // used to mean this screen ignored both Dark mode and the accent
    // picker entirely. In edit mode this is just an identity `Builder` so
    // the subtree inherits whatever `Theme.of(context)` the app's real
    // `MaterialApp` already set up.
    final Widget Function(Widget) themeWrap = widget.isEditMode
        ? (child) => child
        : (child) => Theme(data: AppTheme.onboardingLight, child: child);

    return themeWrap(
      Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: widget.isEditMode ? context.palette.background : colorScheme.surface,
              resizeToAvoidBottomInset: true,
              body: SafeArea(
                child: Column(
                  children: [
                    OnboardingHeader(
                      stepNumber: AccountSetupStep.profile.stepNumber,
                      totalSteps: AccountSetupStep.totalSteps,
                      title: widget.isEditMode ? 'Edit Profile' : 'Profile Setup',
                      // No back arrow during onboarding: the account
                      // already exists by this point, and there is nowhere
                      // useful to return to. From the Me tab, though, "Edit"
                      // needs a way back without saving.
                      onBack: widget.isEditMode ? () => context.pop() : null,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: _ProfileCard(
                          institution: institution,
                          photoPath: _photoPath,
                          onPhotoTap: _saving ? null : _openPhotoSheet,
                          nameController: _nameController,
                          nameFocus: _nameFocus,
                          nameTouched: _nameTouched,
                          regNumberController: _regNumberController,
                          regFormat: _regFormat,
                          onRegNumberChanged: _onRegNumberChanged,
                          faculty: _faculty,
                          hasKnownFaculties: _hasKnownFaculties,
                          facultyOptions: institution?.faculties ?? const [],
                          onFacultyChanged: (v) => setState(() {
                            _faculty = v;
                            _departmentController.clear();
                          }),
                          facultyController: _facultyController,
                          departmentController: _departmentController,
                          departmentOptions: _departmentOptions,
                          currentLevel: _currentLevel,
                          onLevelChanged: (v) =>
                              setState(() => _currentLevel = v ?? _currentLevel),
                          entryYear: _entryYear,
                          onEntryYearChanged: _setEntryYear,
                          gradYear: _gradYear,
                          onGradYearChanged: _setGradYear,
                          enabled: !_saving,
                          canSave: _canSave,
                          saving: _saving,
                          onContinue: _handleContinue,
                          onFieldChanged: () => setState(() {}),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _PhotoAction { camera, gallery, remove }

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _ProfileCard extends StatelessWidget {
  final Institution? institution;
  final String? photoPath;
  final VoidCallback? onPhotoTap;
  final TextEditingController nameController;
  final FocusNode nameFocus;
  final bool nameTouched;
  final TextEditingController regNumberController;
  final RegNumberFormat regFormat;
  final ValueChanged<String> onRegNumberChanged;
  final String? faculty;
  final bool hasKnownFaculties;
  final List<String> facultyOptions;
  final ValueChanged<String?> onFacultyChanged;
  final TextEditingController facultyController;
  final TextEditingController departmentController;
  final List<String> departmentOptions;
  final int currentLevel;
  final ValueChanged<int?> onLevelChanged;
  final int? entryYear;
  final ValueChanged<int?> onEntryYearChanged;
  final int? gradYear;
  final ValueChanged<int?> onGradYearChanged;
  final bool enabled;
  final bool canSave;
  final bool saving;
  final VoidCallback onContinue;
  final VoidCallback onFieldChanged;

  const _ProfileCard({
    required this.institution,
    required this.photoPath,
    required this.onPhotoTap,
    required this.nameController,
    required this.nameFocus,
    required this.nameTouched,
    required this.regNumberController,
    required this.regFormat,
    required this.onRegNumberChanged,
    required this.faculty,
    required this.hasKnownFaculties,
    required this.facultyOptions,
    required this.onFacultyChanged,
    required this.facultyController,
    required this.departmentController,
    required this.departmentOptions,
    required this.currentLevel,
    required this.onLevelChanged,
    required this.entryYear,
    required this.onEntryYearChanged,
    required this.gradYear,
    required this.onGradYearChanged,
    required this.enabled,
    required this.canSave,
    required this.saving,
    required this.onContinue,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final regNumber = regNumberController.text.trim();
    final regNumberLooksOff = regNumber.isNotEmpty && !regFormat.matches(regNumber);
    final abbrev = institution?.abbreviation ?? 'your institution';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(
          color: context.palette.surfaceBorder,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Let's set up your profile",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: _AvatarPicker(photoPath: photoPath, onTap: onPhotoTap),
          ),
          const SizedBox(height: 26),
          _ProfileField(
            fieldKey: const ValueKey('fullNameField'),
            label: 'Full Name',
            hint: 'e.g. Ada Obi',
            prefixIcon: Icons.person_outline,
            controller: nameController,
            focusNode: nameFocus,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            onChanged: (_) => onFieldChanged(),
            errorText: nameTouched && nameController.text.trim().isEmpty
                ? 'Enter your full name'
                : null,
          ),
          const SizedBox(height: 18),
          _ProfileField(
            fieldKey: const ValueKey('regNumberField'),
            label: 'Reg. Number',
            hint: regFormat.hint,
            prefixIcon: Icons.badge_outlined,
            controller: regNumberController,
            enabled: enabled,
            onChanged: onRegNumberChanged,
            warningText: regNumberLooksOff
                ? "That doesn't look like a usual $abbrev number. Continue "
                    'anyway?'
                : null,
          ),
          if (hasKnownFaculties) ...[
            const SizedBox(height: 18),
            _ProfileDropdown<String>(
              label: 'Faculty',
              hint: 'Select faculty',
              prefixIcon: Icons.account_balance_outlined,
              value: facultyOptions.contains(faculty) ? faculty : null,
              enabled: enabled,
              items: facultyOptions
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: onFacultyChanged,
            ),
          ] else ...[
            const SizedBox(height: 18),
            _ProfileField(
              label: 'Faculty (optional)',
              hint: 'e.g. Faculty of Engineering',
              prefixIcon: Icons.account_balance_outlined,
              controller: facultyController,
              enabled: enabled,
              onChanged: (v) {
                onFacultyChanged(v.trim().isEmpty ? null : v.trim());
              },
            ),
          ],
          const SizedBox(height: 18),
          if (departmentOptions.isNotEmpty)
            _ProfileDropdown<String>(
              label: 'Department',
              hint: 'Select department',
              prefixIcon: Icons.apartment_outlined,
              value: departmentOptions.contains(departmentController.text)
                  ? departmentController.text
                  : null,
              enabled: enabled,
              items: departmentOptions
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) {
                departmentController.text = v ?? '';
                onFieldChanged();
              },
            )
          else
            _ProfileAutocompleteField(
              fieldKey: const ValueKey('departmentField'),
              label: 'Department',
              hint: 'e.g. Computer Science',
              prefixIcon: Icons.apartment_outlined,
              controller: departmentController,
              enabled: enabled,
              suggestions: _commonNigerianDepartments,
              onChanged: onFieldChanged,
            ),
          const SizedBox(height: 18),
          _ProfileDropdown<int>(
            label: 'Current Level',
            hint: 'Select level',
            prefixIcon: Icons.school_outlined,
            value: currentLevel,
            enabled: enabled,
            items: AppConstants.levels
                .map((l) => DropdownMenuItem(value: l, child: Text('$l Level')))
                .toList(),
            onChanged: onLevelChanged,
          ),
          const SizedBox(height: 18),
          _YearRow(
            entryYear: entryYear,
            gradYear: gradYear,
            enabled: enabled,
            onEntryYearChanged: onEntryYearChanged,
            onGradYearChanged: onGradYearChanged,
          ),
          const SizedBox(height: 10),
          _RemainingSemestersLine(
            currentLevel: currentLevel,
            entryYear: entryYear,
            gradYear: gradYear,
          ),
          const SizedBox(height: 26),
          _ProfileContinueButton(
            enabled: canSave,
            saving: saving,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final String? photoPath;
  final VoidCallback? onTap;

  const _AvatarPicker({required this.photoPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 128,
        height: 128,
        child: Stack(
          children: [
            ClipOval(
              child: SizedBox(
                width: 128,
                height: 128,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasPhoto)
                      Image.file(File(photoPath!), fit: BoxFit.cover)
                    else
                      ColoredBox(
                        color: context.palette.primary.withValues(alpha: 0.12),
                        child: CustomPaint(painter: _AvatarSilhouettePainter(context.palette.hintText)),
                      ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 56,
                        color: context.palette.bodyText
                            .withValues(alpha: hasPhoto ? 0.70 : 0.82),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasPhoto)
              Positioned(
                top: 0,
                right: 0,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Material(
                    color: context.palette.bodyText.withValues(alpha: 0.85),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onTap,
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Head + shoulders silhouette for the empty avatar state — deliberately
/// not an asset (see the design spec this was built against).
class _AvatarSilhouettePainter extends CustomPainter {
  final Color color;

  const _AvatarSilhouettePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final centerX = size.width / 2;

    const headRadius = 19.0; // 38dp diameter
    final headTop = size.height * 0.26;
    canvas.drawCircle(Offset(centerX, headTop + headRadius), headRadius, paint);

    final shoulders = Rect.fromCenter(
      center: Offset(centerX, size.height - 6),
      width: 76,
      height: 56,
    );
    canvas.drawOval(shoulders, paint);
  }

  @override
  bool shouldRepaint(covariant _AvatarSilhouettePainter oldDelegate) => oldDelegate.color != color;
}

class _PhotoSourceSheet extends StatelessWidget {
  final bool hasPhoto;
  const _PhotoSourceSheet({required this.hasPhoto});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _PhotoSourceOption(
            icon: Icons.photo_camera_outlined,
            label: 'Take a photo',
            onTap: () => Navigator.of(context).pop(_PhotoAction.camera),
          ),
          Divider(height: 1, color: context.palette.divider),
          _PhotoSourceOption(
            icon: Icons.photo_library_outlined,
            label: 'Choose from gallery',
            onTap: () => Navigator.of(context).pop(_PhotoAction.gallery),
          ),
          if (hasPhoto) ...[
            Divider(height: 1, color: context.palette.divider),
            _PhotoSourceOption(
              icon: Icons.delete_outline,
              label: 'Remove photo',
              color: context.palette.error,
              onTap: () => Navigator.of(context).pop(_PhotoAction.remove),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PhotoSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _PhotoSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 20, color: resolvedColor),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: resolvedColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label + bordered/shadowed input shell shared by every field on this
/// screen — plain text entry variant.
class _ProfileField extends StatefulWidget {
  final Key? fieldKey;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final List<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? warningText;

  const _ProfileField({
    this.fieldKey,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.onChanged,
    this.errorText,
    this.warningText,
  });

  @override
  State<_ProfileField> createState() => _ProfileFieldState();
}

class _ProfileFieldState extends State<_ProfileField> {
  late final FocusNode _internalFocus = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _internalFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = _internalFocus.hasFocus);
  }

  @override
  void dispose() {
    _internalFocus.removeListener(_onFocusChange);
    if (widget.focusNode == null) _internalFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: widget.label,
      focused: _focused,
      hasError: widget.errorText != null,
      errorText: widget.errorText,
      warningText: widget.warningText,
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(widget.prefixIcon, size: 22, color: context.palette.hintText),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: widget.fieldKey,
              controller: widget.controller,
              focusNode: _internalFocus,
              enabled: widget.enabled,
              textCapitalization: widget.textCapitalization,
              autofillHints: widget.autofillHints,
              onChanged: widget.onChanged,
              style: TextStyle(
                color: context.palette.bodyText,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: context.palette.hintText,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class _ProfileAutocompleteField extends StatelessWidget {
  final Key? fieldKey;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextEditingController controller;
  final bool enabled;
  final List<String> suggestions;
  final VoidCallback onChanged;

  const _ProfileAutocompleteField({
    this.fieldKey,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.controller,
    required this.enabled,
    required this.suggestions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: FocusNode(),
      optionsBuilder: (value) {
        if (value.text.trim().isEmpty) return const Iterable<String>.empty();
        final query = value.text.trim().toLowerCase();
        return suggestions.where((s) => s.toLowerCase().contains(query));
      },
      onSelected: (_) => onChanged(),
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        return _ProfileField(
          fieldKey: fieldKey,
          label: label,
          hint: hint,
          prefixIcon: prefixIcon,
          controller: fieldController,
          focusNode: focusNode,
          enabled: enabled,
          onChanged: (_) => onChanged(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: options
                    .map(
                      (o) => ListTile(
                        title: Text(o),
                        onTap: () => onSelected(o),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileDropdown<T> extends StatefulWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final T? value;
  final bool enabled;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _ProfileDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.value,
    required this.enabled,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_ProfileDropdown<T>> createState() => _ProfileDropdownState<T>();
}

class _ProfileDropdownState<T> extends State<_ProfileDropdown<T>> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _FieldShell(
      label: widget.label,
      focused: _focused,
      hasError: false,
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(widget.prefixIcon, size: 22, color: context.palette.hintText),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<T>(
                initialValue: widget.value,
                focusNode: _focusNode,
                isExpanded: true,
                icon: Icon(
                  Icons.expand_more,
                  size: 24,
                  color: context.palette.hintText,
                ),
                hint: Text(
                  widget.hint,
                  style: TextStyle(
                    color: context.palette.hintText,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
                items: widget.items,
                onChanged: widget.enabled ? widget.onChanged : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared bordered/shadowed 58dp shell + label + optional error/warning
/// line beneath — every field on this screen renders through this.
class _FieldShell extends StatelessWidget {
  final String label;
  final bool focused;
  final bool hasError;
  final String? errorText;
  final String? warningText;
  final Widget child;

  const _FieldShell({
    required this.label,
    required this.focused,
    required this.hasError,
    this.errorText,
    this.warningText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.palette.bodyText,
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 58,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? context.palette.error
                  : (focused ? colorScheme.primary : context.palette.surfaceBorder),
              width: hasError ? 1.8 : (focused ? 1.8 : 1.2),
            ),
            boxShadow: focused && !hasError
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: TextStyle(
                color: context.palette.error,
                fontSize: 13.5,
              ),
            ),
          ),
        ] else if (warningText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              warningText!,
              style: TextStyle(
                color: context.palette.amber,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _YearRow extends StatelessWidget {
  final int? entryYear;
  final int? gradYear;
  final bool enabled;
  final ValueChanged<int?> onEntryYearChanged;
  final ValueChanged<int?> onGradYearChanged;

  const _YearRow({
    required this.entryYear,
    required this.gradYear,
    required this.enabled,
    required this.onEntryYearChanged,
    required this.onGradYearChanged,
  });

  /// The `current ± N` window is fine as a default range, but a value
  /// saved in a past year can fall outside it once "current year" shifts --
  /// e.g. a profile saved in 2020 with `entryYear: 2020` is silently
  /// orphaned from an `entryYearOptions()` window computed in 2026. A
  /// `DropdownButtonFormField` whose `value` isn't among its own `items`
  /// asserts (`items.where(...).length == 1` fails at zero matches), which
  /// is exactly what made this screen crash on an older saved profile.
  /// Always folding the already-selected value into its own options list
  /// guarantees it can never go missing.
  static List<int> _entryYearOptions([int? selected]) {
    final current = DateTime.now().year;
    final years = {for (var y = current; y >= current - 10; y--) y};
    if (selected != null) years.add(selected);
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  static List<int> _gradYearOptions([int? selected]) {
    final current = DateTime.now().year;
    final years = {for (var y = current - 10; y <= current + 10; y++) y};
    if (selected != null) years.add(selected);
    return years.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final entryField = _ProfileDropdown<int>(
      key: const ValueKey('entryYearField'),
      label: 'Entry Year',
      hint: 'Select year',
      prefixIcon: Icons.calendar_today_outlined,
      value: entryYear,
      enabled: enabled,
      items: _entryYearOptions(entryYear)
          .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
          .toList(),
      onChanged: onEntryYearChanged,
    );
    final gradField = _ProfileDropdown<int>(
      label: 'Expected Graduation',
      hint: 'Select year',
      prefixIcon: Icons.event_available_outlined,
      value: gradYear,
      enabled: enabled,
      items: _gradYearOptions(gradYear)
          .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
          .toList(),
      onChanged: onGradYearChanged,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              entryField,
              const SizedBox(height: 18),
              gradField,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: entryField),
            const SizedBox(width: 12),
            Expanded(child: gradField),
          ],
        );
      },
    );
  }
}

class _RemainingSemestersLine extends StatelessWidget {
  final int currentLevel;
  final int? entryYear;
  final int? gradYear;

  const _RemainingSemestersLine({
    required this.currentLevel,
    required this.entryYear,
    required this.gradYear,
  });

  @override
  Widget build(BuildContext context) {
    final entry = entryYear;
    final grad = gradYear;
    if (entry == null || grad == null) return const SizedBox.shrink();

    final totalSemesters = (grad - entry) * AppConstants.semestersPerLevel;
    final levelsCompleted = ((currentLevel - 100) / 100).floor();
    final semestersCompleted = levelsCompleted * AppConstants.semestersPerLevel;
    final rawRemaining = totalSemesters - semestersCompleted;
    final remaining = rawRemaining < 0 ? 0 : rawRemaining;
    final spanYears = grad - entry;

    String? warning;
    if (grad <= entry) {
      warning = 'Expected graduation must be after entry year.';
    } else if (rawRemaining < 0) {
      warning = 'Your expected graduation is earlier than your current '
          'level implies — check the years.';
    } else if (spanYears > 8) {
      warning = 'That span looks unusually long — check the years.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "That's $remaining semesters remaining",
          style: TextStyle(
            color: context.palette.secondaryText,
            fontSize: 14.5,
          ),
        ),
        if (warning != null) ...[
          const SizedBox(height: 4),
          Text(
            warning,
            style: TextStyle(
              color: context.palette.amber,
              fontSize: 13.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileContinueButton extends StatefulWidget {
  final bool enabled;
  final bool saving;
  final VoidCallback onPressed;

  const _ProfileContinueButton({
    required this.enabled,
    required this.saving,
    required this.onPressed,
  });

  @override
  State<_ProfileContinueButton> createState() => _ProfileContinueButtonState();
}

class _ProfileContinueButtonState extends State<_ProfileContinueButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final interactive = enabled && !widget.saving;

    return GestureDetector(
      key: const ValueKey('profileContinueButtonTap'),
      onTap: interactive ? widget.onPressed : null,
      onTapDown: interactive ? (_) => _setPressed(true) : null,
      onTapUp: interactive ? (_) => _setPressed(false) : null,
      onTapCancel: interactive ? () => _setPressed(false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: enabled && !_pressed
              ? LinearGradient(
                  colors: [
                    context.palette.primaryGradientStart,
                    context.palette.primary,
                  ],
                )
              : null,
          color: !enabled
              ? context.palette.disabledFill
              : (_pressed ? context.palette.primary : null),
          boxShadow: !enabled
              ? null
              : _pressed
                  ? [
                      BoxShadow(
                        color: context.palette.primary.withValues(alpha: 0.22),
                        blurRadius: 4,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: context.palette.primary.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: context.palette.primary.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
        ),
        child: widget.saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                'Continue',
                style: TextStyle(
                  color: enabled ? Colors.white : context.palette.disabledText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Add results — step 2 of Act 1, rebuilt.
///
/// Two internal phases inside this one route: intake (session, slip upload,
/// manual course-code entry) and grades (one grade per course, then
/// `commitDraft()` and on to the GPA reveal). "Grades" is step 3 of the
/// four-step sequence conceptually, but there is no separate screen/design
/// for it yet, so it stays a second phase of this widget rather than a new
/// route — see the judgment call noted in the PR/commit description.
///
/// Slip extraction requires a Supabase Edge Function proxy that does not
/// exist yet (see AGENTS.md's "Backend | Not started"). Every real
/// extraction attempt below therefore resolves to failure or offline, NEVER
/// a fabricated success — the photo is kept only as a local visual
/// reference (`OnboardingDraft.slipImageBytes`) the student can see while
/// typing courses in the grades phase.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/course_result.dart';
import '../../../domain/models/grading_scheme.dart';
import '../../../shared/widgets/onboarding_header.dart';
import '../providers/onboarding_provider.dart';

enum _Phase { intake, grades }

enum _SlipStatus { idle, selected, uploading, success, failure, offline }

typedef PickImage = Future<Uint8List?> Function(ImageSource source);
typedef CheckOnline = Future<bool> Function();

Future<Uint8List?> _defaultPickImage(ImageSource source) async {
  final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
  if (file == null) return null;
  return file.readAsBytes();
}

Future<bool> _defaultCheckOnline() async {
  final results = await Connectivity().checkConnectivity();
  return !results.contains(ConnectivityResult.none);
}

class AddFirstResultsScreen extends ConsumerStatefulWidget {
  /// Test-only overrides — the real `image_picker`/`connectivity_plus`
  /// plugins have no platform implementation under `flutter test`, so
  /// widget tests inject a fake here instead of mocking plugin channels.
  final PickImage? debugPickImage;
  final CheckOnline? debugCheckOnline;

  const AddFirstResultsScreen({
    super.key,
    this.debugPickImage,
    this.debugCheckOnline,
  });

  @override
  ConsumerState<AddFirstResultsScreen> createState() =>
      _AddFirstResultsScreenState();
}

class _AddFirstResultsScreenState extends ConsumerState<AddFirstResultsScreen> {
  _Phase _phase = _Phase.intake;
  _SlipStatus _slipStatus = _SlipStatus.idle;
  bool _showManualRows = false;

  late final PickImage _pickImage = widget.debugPickImage ?? _defaultPickImage;
  late final CheckOnline _checkOnline =
      widget.debugCheckOnline ?? _defaultCheckOnline;

  Future<void> _openImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: OnboardingLightPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Theme(
        data: AppTheme.onboardingLight,
        child: const _ImageSourceSheet(),
      ),
    );
    if (source == null) return;
    await _pickAndStore(source);
  }

  Future<void> _pickAndStore(ImageSource source) async {
    try {
      final bytes = await _pickImage(source);
      if (bytes == null) return; // user backed out of the picker
      if (!mounted) return;
      ref.read(onboardingDraftProvider.notifier).setSlipImage(bytes);
      setState(() => _slipStatus = _SlipStatus.selected);
      unawaited(_extractSlip());
    } catch (_) {
      if (!mounted) return;
      _fallbackAfterPermissionDenial();
    }
  }

  /// "Handle permission denial with a clear message and a route to manual
  /// entry — never a dead end." Any picker failure (permission denied,
  /// camera unavailable, etc.) lands here, not just permission errors
  /// specifically — the fallback is the same either way.
  void _fallbackAfterPermissionDenial() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Couldn't access your camera or photos. Enter your courses "
          'manually instead.',
        ),
      ),
    );
    setState(() => _showManualRows = true);
  }

  Future<void> _extractSlip() async {
    setState(() => _slipStatus = _SlipStatus.uploading);
    final online = await _checkOnline();
    if (!mounted) return;
    if (!online) {
      setState(() => _slipStatus = _SlipStatus.offline);
      return;
    }
    // No Edge Function to call yet — never fabricate a success. A brief
    // delay keeps the "uploading" state visible rather than flashing past
    // it, matching what a real (currently failing) network round-trip
    // would look like.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _slipStatus = _SlipStatus.failure);
  }

  void _discardImage() {
    ref.read(onboardingDraftProvider.notifier).setSlipImage(null);
    setState(() => _slipStatus = _SlipStatus.idle);
  }

  void _cancelUpload() => setState(() => _slipStatus = _SlipStatus.selected);

  Future<void> _openSessionSheet(
    OnboardingDraft draft,
    OnboardingDraftNotifier notifier,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OnboardingLightPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Theme(
        data: AppTheme.onboardingLight,
        child: _SessionPickerSheet(
          session: draft.session,
          level: draft.level,
          term: draft.term,
          scheme: draft.scheme,
          onDone: notifier.setSemesterContext,
        ),
      ),
    );
  }

  bool _gradesReady(OnboardingDraft draft) {
    final rows = draft.rows
        .where((r) => r.courseCode.trim().isNotEmpty && r.creditUnit != null)
        .toList();
    return rows.isNotEmpty && rows.every((r) => r.grade != null);
  }

  void _handleContinue(OnboardingDraft draft) {
    if (_phase == _Phase.intake) {
      setState(() => _phase = _Phase.grades);
      return;
    }
    ref.read(onboardingDraftProvider.notifier).commitDraft();
    context.go(Routes.gpaReveal);
  }

  void _handleBack() {
    if (_phase == _Phase.grades) {
      setState(() => _phase = _Phase.intake);
      return;
    }
    context.go(Routes.institutionSetup);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);

    final hasManualRows = draft.rows.any(
      (r) => r.courseCode.trim().isNotEmpty && r.creditUnit != null,
    );
    final hasImage = draft.slipImageBytes != null;
    final canContinue = _phase == _Phase.intake
        ? (hasImage || hasManualRows)
        : _gradesReady(draft);

    return Theme(
      data: AppTheme.onboardingLight,
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;

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
                          stepNumber: (_phase == _Phase.intake
                                  ? OnboardingStep.addResults
                                  : OnboardingStep.grades)
                              .stepNumber,
                          totalSteps: OnboardingStep.totalSteps,
                          title: (_phase == _Phase.intake
                                  ? OnboardingStep.addResults
                                  : OnboardingStep.grades)
                              .title,
                          onBack: _handleBack,
                        ),
                        Expanded(
                          child: _phase == _Phase.intake
                              ? _IntakeView(
                                  draft: draft,
                                  notifier: notifier,
                                  slipStatus: _slipStatus,
                                  showManualRows:
                                      _showManualRows || hasManualRows,
                                  onSessionTap: () =>
                                      _openSessionSheet(draft, notifier),
                                  onUploadTap: _openImageSourceSheet,
                                  onDiscardImage: _discardImage,
                                  onCancelUpload: _cancelUpload,
                                  onRetake: _openImageSourceSheet,
                                  onManualEntryTap: () =>
                                      setState(() => _showManualRows = true),
                                )
                              : _GradesView(draft: draft, notifier: notifier),
                        ),
                        _ContinueFooter(
                          enabled: canContinue,
                          label: _phase == _Phase.intake
                              ? 'Continue'
                              : 'Calculate my GPA',
                          onPressed: () => _handleContinue(draft),
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

/// Phase 1 — session card, slip upload (with every state), manual entry,
/// privacy card. Everything above the pinned Continue footer scrolls as one
/// unit.
class _IntakeView extends StatelessWidget {
  final OnboardingDraft draft;
  final OnboardingDraftNotifier notifier;
  final _SlipStatus slipStatus;
  final bool showManualRows;
  final VoidCallback onSessionTap;
  final VoidCallback onUploadTap;
  final VoidCallback onDiscardImage;
  final VoidCallback onCancelUpload;
  final VoidCallback onRetake;
  final VoidCallback onManualEntryTap;

  const _IntakeView({
    required this.draft,
    required this.notifier,
    required this.slipStatus,
    required this.showManualRows,
    required this.onSessionTap,
    required this.onUploadTap,
    required this.onDiscardImage,
    required this.onCancelUpload,
    required this.onRetake,
    required this.onManualEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SessionSelectorCard(
            session: draft.session,
            level: draft.level,
            term: draft.term,
            scheme: draft.scheme,
            onTap: onSessionTap,
          ),
          const SizedBox(height: 20),
          if (draft.slipImageBytes == null)
            _UploadDropzone(onTap: onUploadTap)
          else
            _SlipPreview(
              bytes: draft.slipImageBytes!,
              status: slipStatus,
              onDiscard: onDiscardImage,
              onCancelUpload: onCancelUpload,
              onRetake: onRetake,
              onManualFallback: onManualEntryTap,
            ),
          const _OrDivider(),
          if (!showManualRows)
            _ManualEntryButton(onTap: onManualEntryTap)
          else
            _ManualCourseRows(draft: draft, notifier: notifier),
          const SizedBox(height: 20),
          const _PrivacyCard(),
        ],
      ),
    );
  }
}

class _SessionSelectorCard extends StatelessWidget {
  final String session;
  final int level;
  final SemesterTerm term;
  final GradingScheme scheme;
  final VoidCallback onTap;

  const _SessionSelectorCard({
    required this.session,
    required this.level,
    required this.term,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(
          color: OnboardingLightPalette.searchBorder,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$session Session',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scheme.termLabel(term),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 24,
                    color: OnboardingLightPalette.hintText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionPickerSheet extends StatefulWidget {
  final String session;
  final int level;
  final SemesterTerm term;
  final GradingScheme scheme;
  final void Function({String? session, int? level, SemesterTerm? term}) onDone;

  const _SessionPickerSheet({
    required this.session,
    required this.level,
    required this.term,
    required this.scheme,
    required this.onDone,
  });

  @override
  State<_SessionPickerSheet> createState() => _SessionPickerSheetState();
}

class _SessionPickerSheetState extends State<_SessionPickerSheet> {
  late String _session = widget.session;
  late int _level = widget.level;
  late SemesterTerm _term = widget.term;

  static List<String> _nearbySessions() {
    final now = DateTime.now();
    final current = now.month >= 9 ? now.year : now.year - 1;
    return [for (var i = -2; i <= 1; i++) '${current + i}/${current + i + 1}'];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sessions = {..._nearbySessions(), _session}.toList()..sort();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session & level',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              const _PickerLabel('Session'),
              const SizedBox(height: 8),
              _ChipGroup(
                children: [
                  for (final s in sessions)
                    _PickerChip(
                      label: s,
                      selected: s == _session,
                      onTap: () => setState(() => _session = s),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const _PickerLabel('Level'),
              const SizedBox(height: 8),
              _ChipGroup(
                children: [
                  for (final l in AppConstants.levels)
                    _PickerChip(
                      label: '${l}L',
                      selected: l == _level,
                      onTap: () => setState(() => _level = l),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const _PickerLabel('Term'),
              const SizedBox(height: 8),
              _ChipGroup(
                children: [
                  for (final t in SemesterTerm.values)
                    _PickerChip(
                      label: widget.scheme.termLabel(t),
                      selected: t == _term,
                      onTap: () => setState(() => _term = t),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    widget.onDone(
                      session: _session,
                      level: _level,
                      term: _term,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

class _PickerLabel extends StatelessWidget {
  final String text;
  const _PickerLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _ChipGroup extends StatelessWidget {
  final List<Widget> children;
  const _ChipGroup({required this.children});

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 8, children: children);
}

class _PickerChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PickerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.08)
          : colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : OnboardingLightPalette.searchBorder,
              width: selected ? 1.6 : 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colorScheme.primary : colorScheme.onSurface,
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed-border upload dropzone — the primary path.
class _UploadDropzone extends StatefulWidget {
  final VoidCallback onTap;
  const _UploadDropzone({required this.onTap});

  @override
  State<_UploadDropzone> createState() => _UploadDropzoneState();
}

class _UploadDropzoneState extends State<_UploadDropzone> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 200,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: _pressed ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: colorScheme.primary.withValues(alpha: 0.45),
          ),
          child: SizedBox.expand(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 44,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upload or take a photo',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'of your course registration slip',
                    style: TextStyle(
                      color: OnboardingLightPalette.secondaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double gapWidth;
  final double radius;

  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 7,
    this.gapWidth = 5,
    this.radius = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(strokeWidth / 2);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.gapWidth != gapWidth ||
      oldDelegate.radius != radius;
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _ImageSourceOption(
            icon: Icons.photo_camera_outlined,
            label: 'Take a photo',
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          const Divider(height: 1, color: OnboardingLightPalette.divider),
          _ImageSourceOption(
            icon: Icons.photo_library_outlined,
            label: 'Choose from gallery',
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurface,
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

/// Selected/uploading/success/failure preview — everything after an image
/// has been picked. Success is unreachable today (see the file doc
/// comment) but fully built so it's ready the moment the Edge Function
/// exists.
class _SlipPreview extends StatelessWidget {
  final Uint8List bytes;
  final _SlipStatus status;
  final VoidCallback onDiscard;
  final VoidCallback onCancelUpload;
  final VoidCallback onRetake;
  final VoidCallback onManualFallback;

  const _SlipPreview({
    required this.bytes,
    required this.status,
    required this.onDiscard,
    required this.onCancelUpload,
    required this.onRetake,
    required this.onManualFallback,
  });

  @override
  Widget build(BuildContext context) {
    final uploading = status == _SlipStatus.uploading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Image.memory(bytes, fit: BoxFit.cover),
              ),
              if (uploading)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.6),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(
                                OnboardingLightPalette.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Reading your slip…',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!uploading)
                Positioned(
                  top: 8,
                  right: 8,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onDiscard,
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (uploading) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onCancelUpload,
              child: const Text('Cancel'),
            ),
          ),
        ],
        if (status == _SlipStatus.success) ...[
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.check_circle,
                  size: 20, color: OnboardingLightPalette.success),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Found 11 courses · 20 units',
                  style: TextStyle(
                    color: OnboardingLightPalette.bodyText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (status == _SlipStatus.failure) ...[
          const SizedBox(height: 12),
          _SlipIssueRow(
            icon: Icons.error_outline,
            iconColor: OnboardingLightPalette.amber,
            title: "Couldn't read that clearly",
            subtitle: 'Try a sharper photo, or enter the courses yourself',
            primaryActionLabel: 'Retake',
            onPrimaryAction: onRetake,
            secondaryActionLabel: 'Enter manually',
            onSecondaryAction: onManualFallback,
          ),
        ],
        if (status == _SlipStatus.offline) ...[
          const SizedBox(height: 12),
          _SlipIssueRow(
            icon: Icons.cloud_off_outlined,
            iconColor: OnboardingLightPalette.amber,
            title: "You're offline",
            subtitle: "Enter your courses manually for now and we'll read the "
                'slip later.',
            primaryActionLabel: 'Enter manually',
            onPrimaryAction: onManualFallback,
          ),
        ],
      ],
    );
  }
}

class _SlipIssueRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const _SlipIssueRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OnboardingLightPalette.amberBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: OnboardingLightPalette.bodyText,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: OnboardingLightPalette.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (secondaryActionLabel != null)
                TextButton(
                  onPressed: onSecondaryAction,
                  child: Text(secondaryActionLabel!),
                ),
              TextButton(
                onPressed: onPrimaryAction,
                style:
                    TextButton.styleFrom(foregroundColor: colorScheme.primary),
                child: Text(primaryActionLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: OnboardingLightPalette.divider,
              thickness: 1,
              height: 1,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'or',
              style: TextStyle(
                color: OnboardingLightPalette.secondaryText,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: OnboardingLightPalette.divider,
              thickness: 1,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualEntryButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ManualEntryButton({required this.onTap});

  @override
  State<_ManualEntryButton> createState() => _ManualEntryButtonState();
}

class _ManualEntryButtonState extends State<_ManualEntryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _pressed
              ? colorScheme.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _pressed
                ? colorScheme.primary
                : OnboardingLightPalette.searchBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          'Enter results manually',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Course code + credit unit list, revealed inline by "Enter results
/// manually". Grades are collected separately, in the grades phase.
class _ManualCourseRows extends StatelessWidget {
  final OnboardingDraft draft;
  final OnboardingDraftNotifier notifier;

  const _ManualCourseRows({required this.draft, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < draft.rows.length; i++) ...[
          _CourseCodeRow(
            row: draft.rows[i],
            onChanged: (r) => notifier.updateRow(i, r),
            onRemove:
                draft.rows.length > 1 ? () => notifier.removeRow(i) : null,
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: notifier.addBlankRow,
          icon: const Icon(Icons.add_outlined),
          label: const Text('Add another course'),
        ),
      ],
    );
  }
}

class _CourseCodeRow extends StatelessWidget {
  final DraftResultRow row;
  final ValueChanged<DraftResultRow> onChanged;
  final VoidCallback? onRemove;

  const _CourseCodeRow({
    required this.row,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(
          color: OnboardingLightPalette.searchBorder,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: row.courseCode,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Course',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => onChanged(row.copyWith(courseCode: v)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              initialValue: row.creditUnit,
              decoration: const InputDecoration(
                labelText: 'Units',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                AppConstants.maxCreditUnit,
                (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
              ),
              onChanged: (v) => onChanged(row.copyWith(creditUnit: v)),
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close_outlined, size: 18),
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 22,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stays on your device',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your results are stored on your phone. Nothing is '
                  'uploaded until you create an account.',
                  style: TextStyle(
                    color: OnboardingLightPalette.secondaryText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Phase 2 — one grade per course, reusing whatever rows intake produced
/// (manual entry, or none at all if the student came in through an
/// image-only path with no manual rows — the "Add a course" action covers
/// that gap).
class _GradesView extends StatelessWidget {
  final OnboardingDraft draft;
  final OnboardingDraftNotifier notifier;

  const _GradesView({required this.draft, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (draft.slipImageBytes != null) ...[
            Text(
              'Your uploaded slip',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _openFullScreenImage(context, draft.slipImageBytes!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Image.memory(
                      draft.slipImageBytes!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.zoom_in_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'Fill in your courses and grades',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < draft.rows.length; i++) ...[
            _CombinedCourseRow(
              row: draft.rows[i],
              scheme: draft.scheme,
              onChanged: (r) => notifier.updateRow(i, r),
              onRemove:
                  draft.rows.length > 1 ? () => notifier.removeRow(i) : null,
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: notifier.addBlankRow,
            icon: const Icon(Icons.add_outlined),
            label: const Text('Add a course'),
          ),
        ],
      ),
    );
  }
}

class _CombinedCourseRow extends StatelessWidget {
  final DraftResultRow row;
  final GradingScheme scheme;
  final ValueChanged<DraftResultRow> onChanged;
  final VoidCallback? onRemove;

  const _CombinedCourseRow({
    required this.row,
    required this.scheme,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(
          color: OnboardingLightPalette.searchBorder,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: row.courseCode,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Course',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => onChanged(row.copyWith(courseCode: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  initialValue: row.creditUnit,
                  decoration: const InputDecoration(
                    labelText: 'Units',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    AppConstants.maxCreditUnit,
                    (i) =>
                        DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                  ),
                  onChanged: (v) => onChanged(row.copyWith(creditUnit: v)),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.close_outlined, size: 18),
                  onPressed: onRemove,
                  tooltip: 'Remove',
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: row.grade,
            decoration: const InputDecoration(
              labelText: 'Grade',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: scheme.grades
                .map(
                  (g) => DropdownMenuItem(
                    value: g.letter,
                    child: Text('${g.letter} (${g.point})'),
                  ),
                )
                .toList(),
            onChanged: (v) => onChanged(row.copyWith(grade: v)),
          ),
        ],
      ),
    );
  }
}

/// Pinned footer — never scrolls with the content above it.
class _ContinueFooter extends StatefulWidget {
  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  const _ContinueFooter({
    super.key,
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_ContinueFooter> createState() => _ContinueFooterState();
}

class _ContinueFooterState extends State<_ContinueFooter> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: GestureDetector(
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
              widget.label,
              style: TextStyle(
                color: enabled
                    ? Colors.white
                    : OnboardingLightPalette.disabledText,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the uploaded slip full-screen, pinch-zoomable — the grades phase's
/// thumbnail is only 140dp tall, too small to actually read course codes
/// and credit units off of while typing them in.
void _openFullScreenImage(BuildContext context, Uint8List bytes) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, secondaryAnimation) =>
          FadeTransition(opacity: animation, child: _FullScreenImageViewer(bytes: bytes)),
    ),
  );
}

class _FullScreenImageViewer extends StatelessWidget {
  final Uint8List bytes;

  const _FullScreenImageViewer({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(child: Image.memory(bytes)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen app-lock gate — shown by `app.dart` whenever
/// `pinProvider`'s `shouldLock` is true (a PIN is set and the current
/// session hasn't unlocked it yet: cold start, or resuming from
/// background). Sits in front of the router entirely, not pushed as a
/// route, so there's no back-gesture/back-button escape from it.
///
/// A gradient-and-glass redesign of what used to be a flat, unstyled
/// screen, built from the same accent-gradient language the dashboard's
/// hero card and the bottom nav already use, so this reads as the same app
/// rather than a bare system dialog. For a returning student with a
/// profile photo, it's shown in a ring at the top — the one piece of
/// personalisation that makes "this is YOUR phone, locked" legible at a
/// glance, instead of a generic lock icon.
///
/// Recovery, all inline (no separate route, to respect the "front of the
/// router" constraint above): [pinMaxAttempts] wrong PINs auto-advances to
/// security questions; failing or skipping those offers a one-time email
/// code as the last resort. Either recovery path, once verified, hands off
/// to [showPinSetupSheet] to set a fresh PIN — which itself unlocks on
/// save, so this screen simply disappears rather than needing its own
/// "you're in" step.
library;

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../providers/auth_provider.dart';
import '../providers/pin_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/security_questions_provider.dart';
import '../widgets/pin_pad.dart';
import 'pin_setup_sheet.dart';

enum _LockPhase { pin, securityQuestions, emailCode, recovered }

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PinPadController();
  bool _wrong = false;
  bool _checking = false;
  _LockPhase _phase = _LockPhase.pin;

  /// A one-shot fade + rise-in for the glass card on first appearance --
  /// the screen used to just snap into view fully formed, which read as
  /// flat/unpolished for something shown on every cold start and every
  /// resume from background.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();
  late final Animation<double> _entranceCurve =
      CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);

  // Security-question recovery.
  List<String>? _questions;
  List<TextEditingController> _answerControllers = const [];
  bool _loadingQuestions = false;
  bool _verifyingAnswers = false;
  String? _sqError;

  // Email-code recovery.
  final _emailCodeController = TextEditingController();
  bool _codeSent = false;
  bool _sendingCode = false;
  bool _verifyingCode = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    // Fire the system prompt automatically the moment this screen appears
    // (a fresh cold start or resume-from-background) so a student who
    // opted in to fingerprint unlock doesn't have to reach for a button
    // first -- the PIN pad underneath is still right there if it's
    // cancelled or fails.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
  }

  Future<void> _tryBiometrics() async {
    if (!mounted || !ref.read(pinProvider).canUseBiometrics) return;
    await ref.read(pinProvider.notifier).unlockWithBiometrics();
  }

  @override
  void dispose() {
    _controller.dispose();
    _entrance.dispose();
    for (final c in _answerControllers) {
      c.dispose();
    }
    _emailCodeController.dispose();
    super.dispose();
  }

  Future<void> _onComplete(String pin) async {
    setState(() => _checking = true);
    final ok = await ref.read(pinProvider.notifier).verify(pin);
    if (!mounted) return;
    if (!ok) {
      HapticFeedback.vibrate();
      final exhausted = ref.read(pinProvider).pinAttemptsExhausted;
      setState(() {
        _wrong = true;
        _checking = false;
      });
      _controller.clear();
      if (exhausted) _beginSecurityQuestionRecovery();
    }
    // A correct PIN flips `pinProvider`'s `unlocked` to true, which is what
    // actually dismisses this screen (app.dart rebuilds once `shouldLock`
    // goes false) -- nothing further to do here on success.
  }

  Future<void> _beginSecurityQuestionRecovery() async {
    setState(() {
      _phase = _LockPhase.securityQuestions;
      _loadingQuestions = true;
      _sqError = null;
    });
    final questions =
        await ref.read(securityQuestionsProvider.notifier).fetchQuestions();
    if (!mounted) return;
    if (questions == null) {
      // Nothing set up (or offline) -- nothing to verify against, so go
      // straight to the email fallback rather than showing empty fields.
      _beginEmailRecovery();
      return;
    }
    setState(() {
      _questions = questions;
      _answerControllers =
          List.generate(questions.length, (_) => TextEditingController());
      _loadingQuestions = false;
    });
  }

  Future<void> _submitSecurityAnswers() async {
    final answers = _answerControllers.map((c) => c.text.trim()).toList();
    if (answers.any((a) => a.isEmpty)) {
      setState(() => _sqError = 'Answer every question.');
      return;
    }
    setState(() {
      _verifyingAnswers = true;
      _sqError = null;
    });
    final ok =
        await ref.read(securityQuestionsProvider.notifier).verify(answers);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _verifyingAnswers = false;
        _sqError = "That doesn't match what we have on record.";
      });
      return;
    }
    await _recoverySucceeded();
  }

  void _beginEmailRecovery() {
    setState(() {
      _phase = _LockPhase.emailCode;
      _loadingQuestions = false;
      _codeSent = false;
      _emailError = null;
    });
  }

  Future<void> _sendEmailCode() async {
    final email = ref.read(authStateProvider).valueOrNull?.email;
    if (email == null) {
      setState(() =>
          _emailError = "We don't have an email on file for this account.");
      return;
    }
    setState(() {
      _sendingCode = true;
      _emailError = null;
    });
    try {
      await ref.read(authStateProvider.notifier).sendPinResetCode(email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _sendingCode = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sendingCode = false;
        _emailError =
            "Couldn't send a code right now -- check your connection and try again.";
      });
    }
  }

  Future<void> _verifyEmailCode() async {
    final email = ref.read(authStateProvider).valueOrNull?.email;
    final code = _emailCodeController.text.trim();
    if (email == null || code.isEmpty) return;
    setState(() {
      _verifyingCode = true;
      _emailError = null;
    });
    try {
      await ref
          .read(authStateProvider.notifier)
          .verifyPinResetCode(email, code);
      if (!mounted) return;
      await _recoverySucceeded();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifyingCode = false;
        _emailError = 'That code is wrong or has expired. Request a new one.';
      });
    }
  }

  Future<void> _recoverySucceeded() async {
    ref.read(pinProvider.notifier).resetFailedAttempts();
    if (!mounted) return;
    setState(() => _phase = _LockPhase.recovered);
    // `showPinSetupSheet` itself calls `setPin`, which flips `unlocked` to
    // true on save -- this screen is torn down by `app.dart` at that point,
    // so there is no further phase to return to on success.
    await showPinSetupSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final canUseBiometrics =
        ref.watch(pinProvider.select((s) => s.canUseBiometrics));
    final profile = ref.watch(studentProfileProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.primaryGradientStart,
                  palette.primaryGradientEnd,
                  Color.lerp(palette.primaryGradientEnd, Colors.black, 0.45)!,
                ],
              ),
            ),
          ),
          // Soft radial lift behind the card, echoing the splash screen's
          // glow treatment rather than a flat gradient with nothing else
          // happening in it. A second, tighter glow directly behind where
          // the card sits adds real depth instead of one flat wash.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.5),
                    radius: 1.1,
                    colors: [
                      Colors.white.withValues(alpha: 0.14),
                      Colors.white.withValues(alpha: 0.0)
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.1),
                    radius: 0.75,
                    colors: [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.0)
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: FadeTransition(
                    opacity: _entranceCurve,
                    child: AnimatedBuilder(
                      animation: _entranceCurve,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, 24 * (1 - _entranceCurve.value)),
                        child: child,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.16),
                                  Colors.white.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  blurRadius: 44,
                                  offset: const Offset(0, 18),
                                ),
                                BoxShadow(
                                  color: palette.primaryGradientStart
                                      .withValues(alpha: 0.22),
                                  blurRadius: 60,
                                  spreadRadius: -10,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _LockAvatar(
                                    photoPath: profile?.photoPath,
                                    initials: profile?.initials),
                                const SizedBox(height: 22),
                                switch (_phase) {
                                  _LockPhase.pin => _PinPhase(
                                      wrong: _wrong,
                                      checking: _checking,
                                      controller: _controller,
                                      canUseBiometrics: canUseBiometrics,
                                      onComplete: (pin) {
                                        setState(() => _wrong = false);
                                        _onComplete(pin);
                                      },
                                      onBiometrics: _tryBiometrics,
                                      onForgotPin:
                                          _beginSecurityQuestionRecovery,
                                    ),
                                  _LockPhase.securityQuestions =>
                                    _SecurityQuestionsPhase(
                                      loading: _loadingQuestions,
                                      verifying: _verifyingAnswers,
                                      questions: _questions,
                                      answerControllers: _answerControllers,
                                      error: _sqError,
                                      onSubmit: _submitSecurityAnswers,
                                      onUseEmailInstead: _beginEmailRecovery,
                                    ),
                                  _LockPhase.emailCode => _EmailCodePhase(
                                      email: ref
                                          .watch(authStateProvider)
                                          .valueOrNull
                                          ?.email,
                                      codeSent: _codeSent,
                                      sending: _sendingCode,
                                      verifying: _verifyingCode,
                                      error: _emailError,
                                      codeController: _emailCodeController,
                                      onSendCode: _sendEmailCode,
                                      onVerifyCode: _verifyEmailCode,
                                    ),
                                  _LockPhase.recovered => Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: CircularProgressIndicator(
                                          color: palette.onPrimary),
                                    ),
                                },
                              ],
                            ),
                          ),
                        ),
                      ),
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

class _LockAvatar extends StatelessWidget {
  final String? photoPath;
  final String? initials;

  const _LockAvatar({required this.photoPath, required this.initials});

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    final onPrimary = context.palette.onPrimary;
    final ring = Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: onPrimary.withValues(alpha: 0.65), width: 1.5),
        // A soft glow behind the avatar (rather than only the drop shadow
        // every other card on this screen already has) is what makes this
        // specific element read as the focal point the first moment the
        // screen appears, instead of just one shape among several.
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: onPrimary.withValues(alpha: 0.28), blurRadius: 28, spreadRadius: 2),
        ],
      ),
      child: path != null && File(path).existsSync()
          ? ClipOval(
              child: Image(
                image: ResizeImage(FileImage(File(path)), width: (82 * MediaQuery.devicePixelRatioOf(context)).round()),
                fit: BoxFit.cover,
              ),
            )
          : ClipOval(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [onPrimary.withValues(alpha: 0.22), onPrimary.withValues(alpha: 0.12)],
                  ),
                ),
                child: Center(
                  child: (initials != null && initials!.isNotEmpty)
                      ? Text(
                          initials!,
                          style: TextStyle(color: onPrimary, fontSize: 27, fontWeight: FontWeight.w700),
                        )
                      : Icon(Icons.lock_rounded, size: 34, color: onPrimary),
                ),
              ),
            ),
    );

    // A small lock badge overlapping the avatar's edge -- the detail that
    // reads as "this is a lock screen with your face on it," not just a
    // generic profile avatar sitting at the top of some other screen.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ring,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.palette.primary,
              border: Border.all(color: onPrimary.withValues(alpha: 0.9), width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Icon(Icons.lock_rounded, size: 14, color: onPrimary),
          ),
        ),
      ],
    );
  }
}

class _PinPhase extends StatelessWidget {
  final bool wrong;
  final bool checking;
  final PinPadController controller;
  final bool canUseBiometrics;
  final ValueChanged<String> onComplete;
  final VoidCallback onBiometrics;
  final VoidCallback onForgotPin;

  const _PinPhase({
    required this.wrong,
    required this.checking,
    required this.controller,
    required this.canUseBiometrics,
    required this.onComplete,
    required this.onBiometrics,
    required this.onForgotPin,
  });

  @override
  Widget build(BuildContext context) {
    final onPrimary = context.palette.onPrimary;
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(pinProvider);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Perform+ is locked',
              style: TextStyle(
                color: onPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              wrong
                  ? (state.remainingPinAttempts > 0
                      ? 'Incorrect PIN. ${state.remainingPinAttempts} attempt${state.remainingPinAttempts == 1 ? '' : 's'} left.'
                      : 'Incorrect PIN.')
                  : 'Enter your PIN to continue',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: wrong
                    ? const Color(0xFFFCA5A5)
                    : onPrimary.withValues(alpha: 0.75),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            if (checking)
              Padding(
                  padding: const EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: onPrimary))
            else ...[
              PinPad(
                controller: controller,
                onComplete: onComplete,
                dotColor: onPrimary,
                keyFillColor: onPrimary.withValues(alpha: 0.12),
                keyLabelColor: onPrimary,
              ),
              if (canUseBiometrics) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  key: const ValueKey('biometricRetryButton'),
                  onPressed: onBiometrics,
                  icon: Icon(Icons.fingerprint, color: onPrimary),
                  label: Text('Use fingerprint',
                      style: TextStyle(
                          color: onPrimary, fontWeight: FontWeight.w600)),
                ),
              ],
              const SizedBox(height: 4),
              TextButton(
                key: const ValueKey('forgotPinTap'),
                onPressed: onForgotPin,
                child: Text('Forgot PIN?',
                    style: TextStyle(
                        color: onPrimary.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SecurityQuestionsPhase extends StatelessWidget {
  final bool loading;
  final bool verifying;
  final List<String>? questions;
  final List<TextEditingController> answerControllers;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onUseEmailInstead;

  const _SecurityQuestionsPhase({
    required this.loading,
    required this.verifying,
    required this.questions,
    required this.answerControllers,
    required this.error,
    required this.onSubmit,
    required this.onUseEmailInstead,
  });

  @override
  Widget build(BuildContext context) {
    final onPrimary = context.palette.onPrimary;
    if (loading) {
      return Padding(
          padding: const EdgeInsets.all(24),
          child: CircularProgressIndicator(color: onPrimary));
    }
    final qs = questions ?? const [];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Answer your security questions',
          style: TextStyle(
              color: onPrimary, fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          "Too many wrong PINs -- let's verify it's really you.",
          style:
              TextStyle(color: onPrimary.withValues(alpha: 0.75), fontSize: 13),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < qs.length; i++) ...[
          Text(qs[i],
              style: TextStyle(
                  color: onPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: answerControllers[i],
            style: TextStyle(color: onPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: onPrimary.withValues(alpha: 0.10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              hintText: 'Your answer',
              hintStyle: TextStyle(color: onPrimary.withValues(alpha: 0.45)),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (error != null) ...[
          Text(error!,
              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13)),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: onPrimary, foregroundColor: Colors.black87),
            onPressed: verifying ? null : onSubmit,
            child: verifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4))
                : const Text('Verify'),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onUseEmailInstead,
          child: Text('Use email instead',
              style: TextStyle(
                  color: onPrimary.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _EmailCodePhase extends StatelessWidget {
  final String? email;
  final bool codeSent;
  final bool sending;
  final bool verifying;
  final String? error;
  final TextEditingController codeController;
  final VoidCallback onSendCode;
  final VoidCallback onVerifyCode;

  const _EmailCodePhase({
    required this.email,
    required this.codeSent,
    required this.sending,
    required this.verifying,
    required this.error,
    required this.codeController,
    required this.onSendCode,
    required this.onVerifyCode,
  });

  @override
  Widget build(BuildContext context) {
    final onPrimary = context.palette.onPrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset your PIN by email',
          style: TextStyle(
              color: onPrimary, fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          email == null
              ? "We don't have an email on file for this account."
              : codeSent
                  ? 'Enter the 6-digit code sent to $email.'
                  : "We'll send a 6-digit code to $email.",
          style:
              TextStyle(color: onPrimary.withValues(alpha: 0.75), fontSize: 13),
        ),
        const SizedBox(height: 20),
        if (codeSent) ...[
          TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: onPrimary,
                fontSize: 22,
                letterSpacing: 6,
                fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              filled: true,
              fillColor: onPrimary.withValues(alpha: 0.10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              counterText: '',
            ),
            maxLength: 6,
          ),
          const SizedBox(height: 14),
        ],
        if (error != null) ...[
          Text(error!,
              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13)),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: onPrimary, foregroundColor: Colors.black87),
            onPressed: email == null
                ? null
                : (sending || verifying)
                    ? null
                    : (codeSent ? onVerifyCode : onSendCode),
            child: (sending || verifying)
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4))
                : Text(codeSent ? 'Verify code' : 'Send code'),
          ),
        ),
        if (codeSent) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: sending ? null : onSendCode,
            child: Text('Resend code',
                style: TextStyle(
                    color: onPrimary.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }
}

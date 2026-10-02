/// Full-screen app-lock gate — shown by `app.dart` whenever
/// `pinProvider`'s `shouldLock` is true (a PIN is set and the current
/// session hasn't unlocked it yet: cold start, or resuming from
/// background). Sits in front of the router entirely, not pushed as a
/// route, so there's no back-gesture/back-button escape from it.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/pin_provider.dart';
import '../widgets/pin_pad.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  final _controller = PinPadController();
  bool _wrong = false;
  bool _checking = false;

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
    super.dispose();
  }

  Future<void> _onComplete(String pin) async {
    setState(() => _checking = true);
    final ok = await ref.read(pinProvider.notifier).verify(pin);
    if (!mounted) return;
    if (!ok) {
      HapticFeedback.vibrate();
      setState(() {
        _wrong = true;
        _checking = false;
      });
      _controller.clear();
    }
    // A correct PIN flips `pinProvider`'s `unlocked` to true, which is what
    // actually dismisses this screen (app.dart rebuilds once `shouldLock`
    // goes false) -- nothing further to do here on success.
  }

  @override
  Widget build(BuildContext context) {
    final canUseBiometrics = ref.watch(pinProvider.select((s) => s.canUseBiometrics));

    return Scaffold(
      backgroundColor: OnboardingLightPalette.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                const Text(
                  'Enter your PIN',
                  style: TextStyle(color: OnboardingLightPalette.bodyText, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _wrong ? 'Incorrect PIN. Try again.' : 'Perform+ is locked',
                  style: TextStyle(
                    color: _wrong ? OnboardingLightPalette.error : OnboardingLightPalette.secondaryText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                if (_checking)
                  const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
                else ...[
                  PinPad(
                    controller: _controller,
                    onComplete: (pin) {
                      setState(() => _wrong = false);
                      _onComplete(pin);
                    },
                  ),
                  if (canUseBiometrics) ...[
                    const SizedBox(height: 20),
                    TextButton.icon(
                      key: const ValueKey('biometricRetryButton'),
                      onPressed: _tryBiometrics,
                      icon: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.primary),
                      label: Text(
                        'Use fingerprint',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

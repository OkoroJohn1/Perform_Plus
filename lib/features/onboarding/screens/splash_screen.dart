import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/bubble_background.dart';
import '../../auth/providers/auth_provider.dart';

/// Splash. Max 1.5s, and it does real work: auth check plus local DB init.
///
/// Your original flow had splash, a logo reveal, a tagline screen and three
/// marketing slides — six screens of promises before the student learned a
/// single thing about themselves. Those are gone. Screen 2 is Add Results —
/// no institution picker, the app is FUTO-only for now.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _revealController,
    curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
    CurvedAnimation(parent: _revealController, curve: Curves.easeOutBack),
  );

  @override
  void initState() {
    super.initState();
    _revealController.forward();
    unawaited(_boot());
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final started = DateTime.now();
    final auth = await ref.read(authStateProvider.future);

    // Floor the splash at 1.2s so the reveal animation is never cut short,
    // ceiling at 1.8s.
    final elapsed = DateTime.now().difference(started);
    if (elapsed < const Duration(milliseconds: 1200)) {
      await Future<void>.delayed(
        const Duration(milliseconds: 1200) - elapsed,
      );
    }
    if (!mounted) return;

    context.go(auth.isSignedIn ? Routes.home : Routes.addFirstResults);
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B0A18);

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          const Positioned.fill(child: BubbleBackground()),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The asset already carries its own glow (soft alpha
                    // falloff baked into the PNG) — no extra backdrop needed.
                    const AppLogo(size: 260),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        AppConstants.tagline,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70, height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        'v${AppConstants.version}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: Colors.white54),
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

/// Splash. Does real work in parallel with its own entrance animation: auth
/// resolution (now a real Supabase network call) plus a local DB warm-up.
///
/// Your original flow had splash, a logo reveal, a tagline screen and three
/// marketing slides — six screens of promises before the student learned a
/// single thing about themselves. Those are gone. Screen 2 is the
/// institution picker, so the grading scheme is resolved before any result
/// is entered.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/splash_wave_field.dart';

/// Entrance sequence timing, in ms from the start of `_entrance` — see the
/// design spec this screen was built against. All fit inside the
/// controller's 900ms total duration.
const double _totalMs = 900;
const double _waveStartMs = 0, _waveEndMs = 700;
const double _logoStartMs = 120, _logoEndMs = 570;
const double _wordmarkStartMs = 280, _wordmarkEndMs = 680;
const double _taglineStartMs = 420, _taglineEndMs = 770;
const double _versionStartMs = 600, _versionEndMs = 900;

const Duration _minDisplay = Duration(milliseconds: 900);
const Duration _authTimeout = Duration(milliseconds: 2500);
const Duration _exitDuration = Duration(milliseconds: 250);

/// Tagline switches from two centred lines to one line at this available
/// width — below it, "LEARN SMARTER • TRACK BETTER • GRADUATE STRONGER" (at
/// the specified 11sp/1.6 tracking, ~375dp wide) does not fit even a
/// 360dp-wide device's 312dp of content width after padding.
const double _taglineWrapBreakpoint = 380;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: _exitDuration,
  );
  late final Animation<Color?> _exitBackground = ColorTween(
    begin: SplashPalette.background,
    end: SplashPalette.destinationSurface,
  ).animate(
    CurvedAnimation(
      parent: _exit,
      // "over the final 200ms" of the 250ms exit — starts 50ms in.
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ),
  );
  late final Animation<double> _exitContentOpacity =
      Tween<double>(begin: 1, end: 0).animate(_exit);

  bool _reduceMotion = false;
  bool _bootStarted = false;
  String? _version;

  @override
  void initState() {
    super.initState();
    unawaited(_loadVersion());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootStarted) return;
    _bootStarted = true;

    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
    unawaited(_boot());
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = info.version);
    } catch (_) {
      // The version stamp is cosmetic — never let a platform-channel hiccup
      // (or, in a test environment, a missing plugin) take the splash
      // screen down with it. It just stays blank.
    }
  }

  Future<void> _boot() async {
    final started = DateTime.now();

    // Fire-and-forget local DB warm-up, in parallel with auth resolution
    // and the entrance animation — never sequenced after either.
    unawaited(
      ref
          .read(appDatabaseProvider)
          .customSelect('SELECT 1')
          .getSingleOrNull()
          .catchError((_) => null),
    );

    String destination;
    try {
      final auth =
          await ref.read(authStateProvider.future).timeout(_authTimeout);
      destination = auth.isSignedIn ? Routes.home : Routes.institutionSetup;
    } catch (_) {
      // Timeout or a genuine resolution error — we don't know the session
      // state, so ask the student to sign in again rather than sitting on
      // splash forever.
      destination = Routes.signIn;
    }

    final elapsed = DateTime.now().difference(started);
    final remaining = _minDisplay - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) return;

    await _exitAndNavigate(destination);
  }

  Future<void> _exitAndNavigate(String destination) async {
    if (!_reduceMotion) {
      await _exit.forward();
    }
    if (!mounted) return;
    context.go(destination);
  }

  double _progress(double startMs, double endMs, Curve curve) {
    final t = _entrance.value * _totalMs;
    if (t <= startMs) return 0;
    if (t >= endMs) return 1;
    return curve.transform((t - startMs) / (endMs - startMs));
  }

  @override
  void dispose() {
    _entrance.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final markWidth = math.min(width * 0.42, 180.0);
            final fieldHeight = height * 0.38;
            final taglineWide = width >= _taglineWrapBreakpoint;

            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _exitBackground,
                  builder: (context, _) => ColoredBox(
                    color: _exitBackground.value ?? SplashPalette.background,
                  ),
                ),
                FadeTransition(
                  // The radial glow rides out with the rest of the content —
                  // otherwise, once the base colour has lightened toward the
                  // destination surface, this lift (designed to sit subtly
                  // behind a dark background) is left behind as a stray
                  // purple smudge on a light background.
                  opacity: _exitContentOpacity,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.24),
                          radius: 0.65,
                          colors: [
                            SplashPalette.backgroundGlow,
                            SplashPalette.backgroundGlow.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _exitContentOpacity,
                  child: AnimatedBuilder(
                    animation: _entrance,
                    builder: (context, _) {
                      final waveOpacity = _progress(
                        _waveStartMs,
                        _waveEndMs,
                        Curves.easeOut,
                      );
                      final logoT = _progress(
                        _logoStartMs,
                        _logoEndMs,
                        Curves.easeOutCubic,
                      );
                      final wordmarkT = _progress(
                        _wordmarkStartMs,
                        _wordmarkEndMs,
                        Curves.easeOut,
                      );
                      final taglineT = _progress(
                        _taglineStartMs,
                        _taglineEndMs,
                        Curves.easeOut,
                      );
                      final versionT = _progress(
                        _versionStartMs,
                        _versionEndMs,
                        Curves.easeOut,
                      );

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: fieldHeight,
                            child: Opacity(
                              opacity: waveOpacity,
                              child: WaveField(reduceMotion: _reduceMotion),
                            ),
                          ),
                          Align(
                            alignment: const Alignment(0, -0.12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Opacity(
                                  opacity: logoT,
                                  child: Transform.scale(
                                    scale: 0.92 + 0.08 * logoT,
                                    child: AppLogo(size: markWidth),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Opacity(
                                  opacity: wordmarkT,
                                  child: Transform.translate(
                                    offset: Offset(0, 12 * (1 - wordmarkT)),
                                    child: const _Wordmark(),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Opacity(
                                  opacity: taglineT,
                                  child: Transform.translate(
                                    offset: Offset(0, 8 * (1 - taglineT)),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 24),
                                      child: _Tagline(wide: taglineWide),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: padding.bottom + 48,
                            child: Opacity(
                              opacity: versionT,
                              child: Center(
                                child: Text(
                                  _version == null ? '' : 'v$_version',
                                  style: const TextStyle(
                                    color: SplashPalette.versionText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  static const _style = TextStyle(
    color: SplashPalette.wordmark,
    fontWeight: FontWeight.w600,
    fontSize: 44,
    letterSpacing: -0.5,
    height: 1.0,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('Perform', style: _style),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              SplashPalette.plusGradientStart,
              SplashPalette.plusGradientEnd,
            ],
          ).createShader(bounds),
          child: const Text('+', style: _style),
        ),
      ],
    );
  }
}

class _Tagline extends StatelessWidget {
  final bool wide;

  const _Tagline({required this.wide});

  static const _style = TextStyle(
    color: SplashPalette.tagline,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.6,
    height: 1.5,
  );

  /// Derived from `AppConstants.tagline` ("Learn Smarter. Track Better.
  /// Graduate Stronger.") rather than a parallel hardcoded string, so the
  /// two stay in sync — this screen only controls presentation (caps,
  /// dot separators, wrapping).
  static final List<String> _segments = AppConstants.tagline
      .split('.')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .map((s) => s.toUpperCase())
      .toList();

  static const _dot = WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: 3,
        height: 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: SplashPalette.taglineDot,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );

  static TextSpan _line(List<String> parts) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) spans.add(_dot);
      spans.add(TextSpan(text: parts[i]));
    }
    return TextSpan(children: spans, style: _style);
  }

  @override
  Widget build(BuildContext context) {
    if (wide || _segments.length < 3) {
      return Text.rich(_line(_segments), textAlign: TextAlign.center);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(_line(_segments.sublist(0, 2)), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text.rich(_line(_segments.sublist(2)), textAlign: TextAlign.center),
      ],
    );
  }
}

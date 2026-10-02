/// Auth — Act 2 step 1. Reached AFTER the GPA reveal, never before it — the
/// student already has a computed result to lose by the time they see this
/// screen, which is why the default mode below matters so much.
///
/// MODE DEFAULT: the overwhelming majority of arrivals have no account yet.
/// A real failure already happened from defaulting to "Welcome back" here —
/// a new user hit "invalid login credentials" on the primary button with no
/// visible path to registering. Default to sign-up; only switch to sign-in
/// if this device has signed in/up before (see `lastAccountEmailProvider`).
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_button/sign_in_button.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/onboarding_header.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Drops a trailing " Semester" for the terse inline form the sign-up
/// subtitle needs — `GradingScheme.termLabel` returns e.g. "Harmattan
/// Semester", and "your 100 Level Harmattan Semester GPA" reads as a
/// redundant mouthful next to "Level". Falls back to the full label
/// unchanged for any naming that doesn't end that way.
String _shortTermLabel(String label) {
  const suffix = ' Semester';
  return label.endsWith(suffix)
      ? label.substring(0, label.length - suffix.length)
      : label;
}

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _signUpMode = true;
  bool _modeResolved = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _emailTouched = false;
  bool _passwordEverFocused = false;
  bool _googleLoading = false;
  bool _pendingSignUp = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && mounted) {
        setState(() => _emailTouched = true);
      }
    });
    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus && mounted) {
        setState(() => _passwordEverFocused = true);
      }
    });
    ref.read(lastAccountEmailProvider.future).then((email) {
      if (!mounted || _modeResolved) return;
      _modeResolved = true;
      if (email != null && email.isNotEmpty) {
        setState(() {
          _signUpMode = false;
          _emailController.text = email;
        });
      }
    });
    // Read the CURRENT value once, after the first frame, rather than
    // `ref.listen` -- the flag is set by `AuthNotifier` before this screen
    // is even routed to (the account-deleted handler runs, THEN the router
    // reacts to the resulting signed-out state), so a change-only listener
    // registered after that point would never see it flip.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !ref.read(accountDeletedProvider)) return;
      ref.read(accountDeletedProvider.notifier).state = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This account no longer exists. Your results are still on '
            'this device — sign up to save them again.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _emailValid => _emailRegex.hasMatch(_emailController.text.trim());

  bool get _passwordValid => _signUpMode
      ? _passwordController.text.length >= 8
      : _passwordController.text.isNotEmpty;

  bool get _confirmValid =>
      !_signUpMode ||
      (_confirmController.text.isNotEmpty &&
          _confirmController.text == _passwordController.text);

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _emailValid &&
      _passwordValid &&
      _confirmValid;

  void _switchMode(bool signUp) {
    if (signUp == _signUpMode) return;
    setState(() {
      _signUpMode = signUp;
      _passwordController.clear();
      _confirmController.clear();
      _passwordEverFocused = false;
    });
    ref.read(authStateProvider.notifier).clearError();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    _pendingSignUp = _signUpMode;
    final notifier = ref.read(authStateProvider.notifier);
    if (_signUpMode) {
      notifier.signUpWithEmail(email, password);
    } else {
      notifier.signInWithEmail(email, password);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      await ref.read(authStateProvider.notifier).signInWithGoogle();
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email address above first.'),
        ),
      );
      return;
    }
    try {
      await ref.read(authStateProvider.notifier).resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your email for a reset link.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingDraftProvider);
    final auth = ref.watch(authStateProvider);
    final loading = auth.isLoading;

    ref.listen<bool>(justSignedOutProvider, (previous, next) {
      if (!next) return;
      ref.read(justSignedOutProvider.notifier).state = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You've been logged out successfully.")),
      );
    });

    // `/auth/sign-in` is a pre-auth route (reachable with no session), so
    // the router's redirect never fires while sitting on it — navigate
    // explicitly once sign-in/sign-up actually lands a session. This never
    // fires on failure (`nowSignedIn` stays false), so the user always
    // stays on this screen with the error visible — never rely on the
    // router guard to notice the state change instead, which is what
    // previously hung the app on splash after a failed login.
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      final wasSignedIn = previous?.valueOrNull?.isSignedIn ?? false;
      final nowSignedIn = next.valueOrNull?.isSignedIn ?? false;
      if (wasSignedIn || !nowSignedIn) return;
      if (_pendingSignUp) {
        // Sign-up always goes to profile setup — there is no scenario on
        // this path where the profile could already be complete.
        context.go(Routes.profileSetup);
      } else {
        context.go(
          next.valueOrNull!.profileComplete ? Routes.home : Routes.profileSetup,
        );
      }
    });

    return Theme(
      data: AppTheme.onboardingLight,
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          const showGoogle = kIsWeb || AppConstants.enableGoogleSignInOnAndroid;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: colorScheme.surface,
              resizeToAvoidBottomInset: true,
              body: SafeArea(
                child: Column(
                  children: [
                    OnboardingHeader(
                      stepNumber: AccountSetupStep.account.stepNumber,
                      totalSteps: AccountSetupStep.totalSteps,
                      title: _signUpMode ? 'Create Account' : 'Sign In',
                      onBack: () => context.go(Routes.gpaReveal),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Center(
                                child: _AuthCard(
                                  signUpMode: _signUpMode,
                                  draft: draft,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  confirmController: _confirmController,
                                  emailFocus: _emailFocus,
                                  passwordFocus: _passwordFocus,
                                  emailTouched: _emailTouched,
                                  emailValid: _emailValid,
                                  passwordEverFocused: _passwordEverFocused,
                                  obscurePassword: _obscurePassword,
                                  obscureConfirm: _obscureConfirm,
                                  onTogglePasswordVisibility: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  onToggleConfirmVisibility: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                  onFieldChanged: () => setState(() {}),
                                  onForgotPassword: _handleForgotPassword,
                                  authError: auth.error,
                                  onSwitchToSignIn: () {
                                    _switchMode(false);
                                  },
                                  loading: loading,
                                  canSubmit: _canSubmit && !loading,
                                  onSubmit: _submit,
                                  showGoogle: showGoogle,
                                  googleLoading: _googleLoading,
                                  onGoogleSignIn: _handleGoogleSignIn,
                                  onSwitchMode: _switchMode,
                                ),
                              ),
                            ),
                          );
                        },
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

class _AuthCard extends StatelessWidget {
  final bool signUpMode;
  final OnboardingDraft draft;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final bool emailTouched;
  final bool emailValid;
  final bool passwordEverFocused;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmVisibility;
  final VoidCallback onFieldChanged;
  final VoidCallback onForgotPassword;
  final Object? authError;
  final VoidCallback onSwitchToSignIn;
  final bool loading;
  final bool canSubmit;
  final VoidCallback onSubmit;
  final bool showGoogle;
  final bool googleLoading;
  final VoidCallback onGoogleSignIn;
  final ValueChanged<bool> onSwitchMode;

  const _AuthCard({
    required this.signUpMode,
    required this.draft,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.emailTouched,
    required this.emailValid,
    required this.passwordEverFocused,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmVisibility,
    required this.onFieldChanged,
    required this.onForgotPassword,
    required this.authError,
    required this.onSwitchToSignIn,
    required this.loading,
    required this.canSubmit,
    required this.onSubmit,
    required this.showGoogle,
    required this.googleLoading,
    required this.onGoogleSignIn,
    required this.onSwitchMode,
  });

  String get _resultSubject {
    final committed = draft.committed;
    if (committed == null) return 'your result';
    final term = _shortTermLabel(draft.scheme.termLabel(committed.term));
    return 'your ${committed.level} Level $term GPA';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final errorMessage = authError == null ? null : authErrorMessage(authError!);
    final showAlreadyExistsAction =
        authError != null && isAccountAlreadyExistsError(authError!);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(
          color: OnboardingLightPalette.searchBorder,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              signUpMode ? 'Save your result' : 'Welcome back 👋',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 27,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              signUpMode
                  ? 'Create an account to keep $_resultSubject and track it '
                      'over time.'
                  : 'Sign in to continue',
              style: const TextStyle(
                color: OnboardingLightPalette.secondaryText,
                fontSize: 16.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 28),
            _AuthTextField(
              fieldKey: const ValueKey('emailField'),
              controller: emailController,
              focusNode: emailFocus,
              hint: 'Email address',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              enabled: !loading,
              onChanged: (_) => onFieldChanged(),
              errorText: emailTouched &&
                      emailController.text.trim().isNotEmpty &&
                      !emailValid
                  ? 'Enter a valid email address'
                  : null,
            ),
            const SizedBox(height: 16),
            _AuthTextField(
              fieldKey: const ValueKey('passwordField'),
              controller: passwordController,
              focusNode: passwordFocus,
              hint: 'Password',
              prefixIcon: Icons.lock_outline,
              obscureText: obscurePassword,
              textInputAction:
                  signUpMode ? TextInputAction.next : TextInputAction.done,
              autofillHints: [
                signUpMode ? AutofillHints.newPassword : AutofillHints.password,
              ],
              enabled: !loading,
              onChanged: (_) => onFieldChanged(),
              onSubmitted: signUpMode ? null : (_) => canSubmit ? onSubmit() : null,
              suffixIcon: SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                    color: OnboardingLightPalette.hintText,
                  ),
                  onPressed: onTogglePasswordVisibility,
                ),
              ),
            ),
            if (signUpMode && passwordEverFocused) ...[
              const SizedBox(height: 8),
              _PasswordRequirement(met: passwordController.text.length >= 8),
            ],
            if (signUpMode) ...[
              const SizedBox(height: 16),
              _AuthTextField(
                fieldKey: const ValueKey('confirmPasswordField'),
                controller: confirmController,
                hint: 'Confirm password',
                prefixIcon: Icons.lock_outline,
                obscureText: obscureConfirm,
                textInputAction: TextInputAction.done,
                enabled: !loading,
                onChanged: (_) => onFieldChanged(),
                onSubmitted: (_) => canSubmit ? onSubmit() : null,
                suffixIcon: SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 22,
                      color: OnboardingLightPalette.hintText,
                    ),
                    onPressed: onToggleConfirmVisibility,
                  ),
                ),
              ),
            ],
            if (!signUpMode) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 44,
                  child: TextButton(
                    onPressed: onForgotPassword,
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _FormError(
              message: errorMessage,
              action: showAlreadyExistsAction
                  ? TextButton(
                      onPressed: onSwitchToSignIn,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(
                        'Sign in instead',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
            ),
            _PrimaryAuthButton(
              enabled: canSubmit,
              loading: loading,
              label: signUpMode ? 'Create account' : 'Login',
              onPressed: onSubmit,
            ),
            if (showGoogle) ...[
              const _OrDivider(),
              _GoogleButton(loading: googleLoading, onPressed: onGoogleSignIn),
            ],
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: () => onSwitchMode(!signUpMode),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: OnboardingLightPalette.secondaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: signUpMode
                              ? 'Already have an account? '
                              : "Don't have an account? ",
                        ),
                        TextSpan(
                          text: signUpMode ? 'Sign in' : 'Sign up',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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

class _AuthTextField extends StatefulWidget {
  final Key? fieldKey;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
  final String? errorText;

  const _AuthTextField({
    this.fieldKey,
    required this.controller,
    this.focusNode,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.suffixIcon,
    this.errorText,
  });

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  late final FocusNode _internalFocus = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _internalFocus.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) setState(() => _focused = _internalFocus.hasFocus);
  }

  @override
  void dispose() {
    _internalFocus.removeListener(_handleFocusChange);
    if (widget.focusNode == null) _internalFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 60,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? OnboardingLightPalette.error
                  : (_focused
                      ? colorScheme.primary
                      : OnboardingLightPalette.searchBorder),
              width: hasError ? 1.8 : (_focused ? 1.8 : 1.2),
            ),
            boxShadow: _focused && !hasError
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
              Icon(
                widget.prefixIcon,
                size: 22,
                color: OnboardingLightPalette.hintText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: widget.fieldKey,
                  controller: widget.controller,
                  focusNode: _internalFocus,
                  enabled: widget.enabled,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 16.5),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      color: OnboardingLightPalette.hintText,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (widget.suffixIcon != null) widget.suffixIcon!,
              const SizedBox(width: 6),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: OnboardingLightPalette.error,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  final bool met;
  const _PasswordRequirement({required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: met
              ? OnboardingLightPalette.success
              : OnboardingLightPalette.hintText,
        ),
        const SizedBox(width: 6),
        const Text(
          'At least 8 characters',
          style: TextStyle(
            color: OnboardingLightPalette.secondaryText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _FormError extends StatelessWidget {
  final String? message;
  final Widget? action;

  const _FormError({required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: OnboardingLightPalette.errorBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 20,
                        color: OnboardingLightPalette.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message!,
                          style: const TextStyle(
                            color: OnboardingLightPalette.bodyText,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (action != null) action!,
                ],
              ),
            ),
    );
  }
}

class _PrimaryAuthButton extends StatefulWidget {
  final bool enabled;
  final bool loading;
  final String label;
  final VoidCallback onPressed;

  const _PrimaryAuthButton({
    required this.enabled,
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_PrimaryAuthButton> createState() => _PrimaryAuthButtonState();
}

class _PrimaryAuthButtonState extends State<_PrimaryAuthButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    // Non-interactive while a request is in flight, but keeps the
    // enabled-coloured look — only truly-disabled (invalid form) gets the
    // grey treatment.
    final interactive = enabled && !widget.loading;

    return GestureDetector(
      key: const ValueKey('primaryAuthButtonTap'),
      onTap: interactive ? widget.onPressed : null,
      onTapDown: interactive ? (_) => _setPressed(true) : null,
      onTapUp: interactive ? (_) => _setPressed(false) : null,
      onTapCancel: interactive ? () => _setPressed(false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 62,
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
                        color:
                            OnboardingLightPalette.primary.withValues(alpha: 0.22),
                        blurRadius: 4,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color:
                            OnboardingLightPalette.primary.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color:
                            OnboardingLightPalette.primary.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
        ),
        child: widget.loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                widget.label,
                style: TextStyle(
                  color: enabled
                      ? Colors.white
                      : OnboardingLightPalette.disabledText,
                  fontSize: 18.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 26),
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

/// Uses `sign_in_button`'s bundled, brand-compliant Google mark rather than
/// a hand-drawn/generated one — Google's guidelines require the sanctioned
/// asset, and Play Store review checks this — while fully re-styling the
/// button itself (height/radius/colours/type) via `SignInButtonBuilder`
/// rather than the pre-baked `SignInButton` look.
class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _GoogleButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 62,
      child: SignInButtonBuilder(
        text: 'Continue with Google',
        onPressed: loading ? () {} : onPressed,
        isLoading: loading,
        elevation: 0,
        backgroundColor: Colors.white,
        highlightColor: const Color(0xFFF9FAFB),
        splashColor: const Color(0xFFF9FAFB),
        textColor: colorScheme.onSurface,
        loadingIndicatorColor: colorScheme.primary,
        textStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 17.5,
          fontWeight: FontWeight.w600,
        ),
        innerPadding: const EdgeInsets.symmetric(horizontal: 14),
        width: double.infinity,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
            color: OnboardingLightPalette.searchBorder,
            width: 1.2,
          ),
        ),
        image: const Image(
          image: AssetImage(
            'assets/logos/google_light.png',
            package: 'sign_in_button',
          ),
          height: 28,
          width: 28,
        ),
      ),
    );
  }
}

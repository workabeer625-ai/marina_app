import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/marina_theme.dart';
import '../../../shared/widgets/marina_wordmark.dart';
import '../../../shared/widgets/common.dart';
import '../data/auth_repository.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> {
  bool networkFailure = false, maintenance = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final configuration =
          (await apiClient.dio.get('/app/configuration')).data;
      final maintenanceEnabled =
          configuration is Map &&
          configuration.entries.any(
            (entry) =>
                entry.key.toString().toLowerCase() == 'maintenancemode' &&
                entry.value.toString().toLowerCase() == 'true',
          );
      if (maintenanceEnabled) {
        if (mounted) setState(() => maintenance = true);
        return;
      }
    } catch (_) {
      if (mounted) setState(() => networkFailure = true);
      return;
    }
    if (!await OnboardingStore.isComplete()) {
      if (mounted) context.go('/onboarding');
      return;
    }
    final restored = await apiClient.restoreSession();
    if (!mounted) return;
    if (!restored && apiClient.lastRestoreWasNetworkFailure) {
      setState(() => networkFailure = true);
      return;
    }
    context.go(restored ? '/home' : '/welcome');
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
    backgroundColor: MarinaColors.midnight,
    body: networkFailure
        ? _AuthErrorScaffold(
            message: context.tr('noInternet'),
            onRetry: () {
              setState(() => networkFailure = false);
              _restore();
            },
          )
        : maintenance
        ? _AuthErrorScaffold(
            message: context.tr('maintenance'),
            onRetry: () {
              setState(() => maintenance = false);
              _restore();
            },
          )
        : const _SplashVisual(),
    ),
  );
}

class _AuthErrorScaffold extends StatelessWidget {
  const _AuthErrorScaffold({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Theme(
    data: MarinaTheme.dark(),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          MarinaGoldButton(
            label: context.tr('retry'),
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    ),
  );
}

class _SplashVisual extends StatelessWidget {
  const _SplashVisual();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/visuals/onboarding-arrival.png',
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xAA070B12),
              Color(0x14070B12),
              Color(0xF0070B12),
            ],
            stops: [0, .55, 1],
          ),
        ),
      ),
      const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 56, 28, 46),
          child: Column(
            children: [
              MarinaWordmark(dark: false),
              Spacer(),
              GoldDivider(width: 130),
              SizedBox(height: 16),
              Text(
                'BEYOND SHOPPING',
                style: TextStyle(
                  color: MarinaColors.goldBright,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
    backgroundColor: MarinaColors.midnight,
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.55),
          radius: 1.2,
          colors: [Color(0xFF182338), MarinaColors.midnight],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 42, 24, 28),
          child: Column(
            children: [
              const MarinaWordmark(dark: false),
              const Spacer(),
              Container(
                width: 158,
                height: 158,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: MarinaGradients.gold,
                  boxShadow: MarinaShadows.glow,
                ),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [MarinaColors.navySoft, MarinaColors.midnight],
                    ),
                  ),
                  child: const MarinaWordmark(
                    dark: false,
                    compact: true,
                    markOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                context.tr('welcome'),
                style: MarinaType.display(context, size: 34, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const GoldDivider(width: 120),
              const SizedBox(height: 16),
              Text(
                context.tr('welcomeSubtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB7C9DB),
                  height: 1.55,
                  fontSize: 14.5,
                ),
              ),
              const Spacer(),
              MarinaGoldButton(
                label: context.tr('login'),
                height: 56,
                onPressed: () => context.push('/login'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/register'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: .04),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: .22),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(context.tr('register')),
              ),
            ],
          ),
        ),
      ),
    ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.sessionExpired = false});

  final bool sessionExpired;

  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  bool phoneMode = false;
  String countryCode = '+966';
  String? error, identityError, passwordError;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final identity = email.text.trim();
    final validEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(identity);
    final digits = identity.replaceAll(RegExp(r'\D'), '');
    final validPhone = digits.length >= 8 && digits.length <= 12;
    final validPassword =
        password.text.length >= 12 &&
        password.text.length <= 128 &&
        password.text.runes.toSet().length >= 4 &&
        RegExp(r'[a-z]').hasMatch(password.text) &&
        RegExp(r'[^a-zA-Z0-9]').hasMatch(password.text) &&
        RegExp(r'[A-Z]').hasMatch(password.text) &&
        RegExp(r'\d').hasMatch(password.text);
    setState(() {
      identityError = phoneMode
          ? (validPhone ? null : 'Enter a valid phone number')
          : (validEmail ? null : 'Enter a valid email address');
      passwordError = validPassword
          ? null
          : 'Use 12?128 characters with uppercase, lowercase, number and symbol';
    });
    if (identityError != null || passwordError != null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await AuthRepository(apiClient)
          .login(phoneMode ? '$countryCode$digits' : identity, password.text);
      if (data['mfaRequired'] == true) {
        if (mounted) {
          context.push(
            '/mfa',
            extra: {
              'email': email.text,
              'password': password.text,
              'setupRequired': data['setupRequired'] == true,
              'sharedKey': data['sharedKey'],
              'account': data['account'],
              'issuer': data['issuer'],
            },
          );
        }
        return;
      }
      await apiClient.saveSession(data);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(
          () => error = apiFailureMessage(e, context.tr('signInFailed')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthForm(
    title: context.tr('login'),
    children: [
      TextField(
        controller: email,
        keyboardType: phoneMode
            ? TextInputType.phone
            : TextInputType.emailAddress,
        autofillHints: phoneMode
            ? const [AutofillHints.telephoneNumber]
            : const [AutofillHints.email],
        decoration: InputDecoration(
          labelText: phoneMode ? 'Phone number' : context.tr('email'),
          errorText: identityError,
          prefixIcon: phoneMode
              ? DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: countryCode,
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    items: const [
                      DropdownMenuItem(value: '+967', child: Text('🇾🇪 +967')),
                      DropdownMenuItem(value: '+966', child: Text('🇸🇦 +966')),
                    ],
                    onChanged: (value) => setState(() => countryCode = value!),
                  ),
                )
              : const Icon(Icons.alternate_email_rounded),
        ),
      ),
      const SizedBox(height: 12),
      _AuthModeSwitch(
        phoneMode: phoneMode,
        onChanged: (value) => setState(() {
          phoneMode = value;
          identityError = null;
          email.clear();
        }),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: password,
        obscureText: true,
        autofillHints: const [AutofillHints.password],
        onSubmitted: (_) => busy ? null : submit(),
        decoration: InputDecoration(
          labelText: context.tr('password'),
          errorText: passwordError,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
        ),
      ),
      if (widget.sessionExpired)
        _ErrorText(context.tr('sessionExpiredMessage'), neutral: true),
      if (error != null) _ErrorText(error!),
      TextButton(
        onPressed: () => context.push('/forgot-password'),
        child: Text(context.tr('forgot')),
      ),
      MarinaGoldButton(
        label: context.tr('login'),
        busy: busy,
        onPressed: busy ? null : submit,
      ),
      TextButton(
        onPressed: () => context.push('/register'),
        child: Text(context.tr('register')),
      ),
    ],
  );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool busy = false;
  String? error, nameError, emailError, passwordError;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final validEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
        .hasMatch(email.text.trim());
    final validPassword =
        password.text.length >= 12 &&
        password.text.length <= 128 &&
        password.text.runes.toSet().length >= 4 &&
        RegExp(r'[a-z]').hasMatch(password.text) &&
        RegExp(r'[^a-zA-Z0-9]').hasMatch(password.text) &&
        RegExp(r'[A-Z]').hasMatch(password.text) &&
        RegExp(r'\d').hasMatch(password.text);
    setState(() {
      nameError = name.text.trim().length >= 2 ? null : 'Enter your full name';
      emailError = validEmail ? null : 'Enter a valid email address';
      passwordError = validPassword
          ? null
          : 'Use 12?128 characters with uppercase, lowercase, number and symbol';
    });
    if (nameError != null || emailError != null || passwordError != null) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await AuthRepository(apiClient)
          .register(name.text, email.text, password.text);
      if (mounted) {
        context.go(
          '/verification?email=${Uri.encodeQueryComponent(email.text.trim())}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = apiFailureMessage(e, context.tr('registerFailed')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthForm(
    title: context.tr('register'),
    children: [
      TextField(
        controller: name,
        decoration: InputDecoration(
          labelText: context.tr('fullName'),
          errorText: nameError,
          prefixIcon: const Icon(Icons.person_outline_rounded),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: email,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: context.tr('email'),
          errorText: emailError,
          prefixIcon: const Icon(Icons.alternate_email_rounded),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: password,
        obscureText: true,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: context.tr('password'),
          errorText: passwordError,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
        ),
      ),
      const SizedBox(height: 10),
      _PasswordStrength(value: password.text),
      if (error != null) _ErrorText(error!),
      const SizedBox(height: 20),
      MarinaGoldButton(
        label: context.tr('register'),
        busy: busy,
        onPressed: busy ? null : submit,
      ),
    ],
  );
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  bool busy = false, sent = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await AuthRepository(apiClient).forgotPassword(email.text);
      if (mounted) setState(() => sent = true);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = apiFailureMessage(e, context.tr('requestFailed')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthForm(
    title: context.tr('forgotPassword'),
    children: [
      Text(
        context.tr('forgotInstructions'),
        style: const TextStyle(color: Color(0xFFB7C9DB), height: 1.55),
      ),
      const SizedBox(height: 18),
      TextField(
        controller: email,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(labelText: context.tr('email')),
      ),
      if (error != null) _ErrorText(error!),
      if (sent)
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(
            context.tr('requestAccepted'),
            style: const TextStyle(color: MarinaColors.goldBright),
          ),
        ),
      const SizedBox(height: 20),
      MarinaGoldButton(
        label: context.tr('sendInstructions'),
        busy: busy,
        onPressed: busy ? null : submit,
      ),
      TextButton(
        onPressed: () => context.push(
          '/reset-password?email=${Uri.encodeQueryComponent(email.text.trim())}',
        ),
        child: Text(context.tr('haveResetToken')),
      ),
    ],
  );
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.initialEmail, this.initialToken});

  final String? initialEmail, initialToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPasswordScreen> {
  late final email = TextEditingController(text: widget.initialEmail);
  late final token = TextEditingController(text: widget.initialToken);
  final password = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    token.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await AuthRepository(apiClient)
          .resetPassword(email.text, token.text, password.text);
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        setState(
          () => error = apiFailureMessage(e, context.tr('invalidResetToken')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthForm(
    title: context.tr('resetPassword'),
    children: [
      TextField(
        controller: email,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(labelText: context.tr('email')),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: token,
        decoration: InputDecoration(labelText: context.tr('resetToken')),
        maxLines: 2,
      ),
      const SizedBox(height: 14),
      TextField(
        controller: password,
        obscureText: true,
        decoration: InputDecoration(labelText: context.tr('newPassword')),
      ),
      if (error != null) _ErrorText(error!),
      const SizedBox(height: 20),
      MarinaGoldButton(
        label: context.tr('resetPassword'),
        busy: busy,
        onPressed: busy ? null : submit,
      ),
    ],
  );
}

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, this.initialEmail, this.initialToken});

  final String? initialEmail, initialToken;

  @override
  State<VerificationScreen> createState() => _VerificationState();
}

class _VerificationState extends State<VerificationScreen> {
  late final email = TextEditingController(text: widget.initialEmail);
  late final token = TextEditingController(text: widget.initialToken);
  bool busy = false;
  String? message;

  @override
  void dispose() {
    email.dispose();
    token.dispose();
    super.dispose();
  }

  Future<void> verify() async {
    setState(() => busy = true);
    try {
      await AuthRepository(apiClient).verifyEmail(email.text, token.text);
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        setState(
          () => message = apiFailureMessage(
            e,
            context.tr('invalidVerificationToken'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resend() async {
    setState(() => busy = true);
    try {
      await AuthRepository(apiClient).resendVerification(email.text);
      if (mounted) {
        setState(() => message = context.tr('requestAccepted'));
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => message = apiFailureMessage(e, context.tr('resendFailed')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthForm(
    title: context.tr('verifyAccount'),
    children: [
      TextField(
        controller: email,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(labelText: context.tr('email')),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: token,
        decoration:
            InputDecoration(labelText: context.tr('verificationToken')),
        maxLines: 2,
      ),
      if (message != null) _ErrorText(message!, neutral: true),
      const SizedBox(height: 20),
      MarinaGoldButton(
        label: context.tr('verify'),
        busy: busy,
        onPressed: busy ? null : verify,
      ),
      TextButton(
        onPressed: busy ? null : resend,
        child: Text(context.tr('resendVerification')),
      ),
    ],
  );
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePasswordScreen> {
  final current = TextEditingController(), next = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => busy = true);
    try {
      await AuthRepository(apiClient).changePassword(current.text, next.text);
      await apiClient.clearSession();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              error = apiFailureMessage(e, context.tr('changePasswordFailed')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthForm(
    title: context.tr('changePassword'),
    children: [
      TextField(
        controller: current,
        obscureText: true,
        decoration:
            InputDecoration(labelText: context.tr('currentPassword')),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: next,
        obscureText: true,
        decoration: InputDecoration(labelText: context.tr('newPassword')),
      ),
      if (error != null) _ErrorText(error!),
      const SizedBox(height: 20),
      MarinaGoldButton(
        label: context.tr('changePassword'),
        busy: busy,
        onPressed: busy ? null : submit,
      ),
    ],
  );
}

class MfaLoginScreen extends StatefulWidget {
  const MfaLoginScreen({
    super.key,
    required this.email,
    required this.password,
    this.setupRequired = false,
    this.sharedKey,
    this.account,
    this.issuer,
  });

  final String email, password;
  final bool setupRequired;
  final String? sharedKey, account, issuer;

  @override
  State<MfaLoginScreen> createState() => _MfaLoginState();
}

class _MfaLoginState extends State<MfaLoginScreen> {
  final code = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await AuthRepository(apiClient)
          .completeMfa(widget.email, widget.password, code.text);
      await apiClient.saveSession(data);
      final recovery = (data['recoveryCodes'] as List?)
          ?.map((x) => x.toString())
          .toList();
      if (mounted && recovery != null && recovery.isNotEmpty) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(context.tr('saveRecoveryCodes')),
            content: SelectableText(recovery.join('\n')),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: Text(context.tr('savedRecoveryCodes')),
              ),
            ],
          ),
        );
      }
      if (mounted) context.go('/admin');
    } catch (e) {
      if (mounted) {
        setState(
          () => error = apiFailureMessage(e, context.tr('invalidSecurityCode')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthForm(
    title: context.tr(
      widget.setupRequired
          ? 'setupSecurityVerification'
          : 'securityVerification',
    ),
    children: [
      if (widget.setupRequired) ...[
        Text(
          context.tr('mfaSetupInstructions'),
          style: const TextStyle(color: Color(0xFFB7C9DB), height: 1.55),
        ),
        const SizedBox(height: 12),
        SelectableText(
          '${widget.issuer ?? 'MARINA'}:${widget.account ?? widget.email}\n${widget.sharedKey ?? ''}',
        ),
      ] else
        Text(
          context.tr('mfaCodeInstructions'),
          style: const TextStyle(color: Color(0xFFB7C9DB), height: 1.55),
        ),
      const SizedBox(height: 18),
      TextField(
        controller: code,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        decoration: InputDecoration(labelText: context.tr('securityCode')),
      ),
      if (error != null) _ErrorText(error!),
      const SizedBox(height: 20),
      MarinaGoldButton(
        label: context.tr('verify'),
        busy: busy,
        onPressed: busy ? null : submit,
      ),
    ],
  );
}

class _AuthModeSwitch extends StatelessWidget {
  const _AuthModeSwitch({required this.phoneMode, required this.onChanged});

  final bool phoneMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1420),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFF283042)),
    ),
    child: Row(
      children: [
        _item(false, Icons.alternate_email_rounded, 'Email'),
        _item(true, Icons.phone_iphone_rounded, 'Phone'),
      ],
    ),
  );

  Widget _item(bool value, IconData icon, String label) => Expanded(
    child: InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: MarinaMotion.fast,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: phoneMode == value ? MarinaGradients.gold : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: phoneMode == value
                  ? MarinaColors.onGold
                  : const Color(0xFF98A1B0),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: phoneMode == value
                    ? MarinaColors.onGold
                    : const Color(0xFF98A1B0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final score = [
      value.length >= 8,
      RegExp(r'[A-Z]').hasMatch(value),
      RegExp(r'\d').hasMatch(value),
      RegExp(r'[^A-Za-z0-9]').hasMatch(value),
    ].where((item) => item).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: AnimatedContainer(
                duration: MarinaMotion.fast,
                height: 3,
                margin: EdgeInsetsDirectional.only(end: index == 3 ? 0 : 5),
                decoration: BoxDecoration(
                  gradient: index < score ? MarinaGradients.gold : null,
                  color: index < score ? null : const Color(0xFF283042),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          score < 2
              ? 'Weak'
              : score < 4
              ? 'Good'
              : 'Strong',
          style: const TextStyle(color: Color(0xFF98A1B0), fontSize: 12),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message, {this.neutral = false});

  final String message;
  final bool neutral;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      message,
      style: TextStyle(
        color: neutral ? const Color(0xFFD8DEE9) : const Color(0xFFE58877),
        fontSize: 13,
        height: 1.45,
      ),
    ),
  );
}

class AuthForm extends StatelessWidget {
  const AuthForm({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
    backgroundColor: MarinaColors.midnight,
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.8),
          radius: 1.3,
          colors: [Color(0xFF1A2438), MarinaColors.midnight],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
              children: [
                Row(
                  children: [
                    MarinaIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      dark: true,
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go('/welcome'),
                    ),
                    const Spacer(),
                    const MarinaWordmark(dark: false, compact: true),
                    const Spacer(),
                    const SizedBox(width: 42),
                  ],
                ),
                const SizedBox(height: 34),
                Text(
                  title,
                  style: MarinaType.display(context, size: 30, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const GoldDivider(width: 110),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: MarinaColors.nightSurface.withValues(alpha: .9),
                    border: Border.all(
                      color: MarinaColors.gold.withValues(alpha: .22),
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .3),
                        blurRadius: 34,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: MarinaTheme.dark(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    ),
  );
}

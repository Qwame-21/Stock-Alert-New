import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/storage/local_db_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/profile_repository.dart';
import '../controllers/registration_cubit.dart';

class LoginScreen extends StatefulWidget {
  final String? expiredMessage;
  const LoginScreen({super.key, this.expiredMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _biometricsEnabled = false;

  // Throttling logic
  int _failedAttempts = 0;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  // Error validations
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _checkBiometricsPreference();
    if (widget.expiredMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.expiredMessage!),
            backgroundColor: AppColors.statusWarning,
          ),
        );
      });
    }
  }

  Future<void> _checkBiometricsPreference() async {
    final enabled = await LocalDbService().read('biometrics_enabled') == 'true';
    final auth = LocalAuthentication();
    final available =
        await auth.isDeviceSupported() && await auth.canCheckBiometrics;
    if (!mounted) return;
    setState(() {
      _biometricsEnabled = enabled && available;
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 30;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        setState(() {
          _cooldownSeconds = 0;
          _failedAttempts = 0;
        });
        timer.cancel();
      } else {
        setState(() {
          _cooldownSeconds--;
        });
      }
    });
  }

  void _validateField(String fieldName, String value) {
    setState(() {
      if (fieldName == 'email') {
        if (value.trim().isEmpty) {
          _emailError = 'Email Address is required';
        } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(value)) {
          _emailError = 'Enter a valid email address';
        } else {
          _emailError = null;
        }
      } else if (fieldName == 'password') {
        if (value.isEmpty) {
          _passwordError = 'Password is required';
        } else if (value.length < 8) {
          _passwordError = 'Password must be at least 8 characters';
        } else {
          _passwordError = null;
        }
      }
    });
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    _validateField('email', email);
    _validateField('password', password);

    if (_emailError != null || _passwordError != null) return;

    try {
      // A manual login is not a password-recovery session.
      await LocalDbService().delete('password_reset_pending');

      // Real Supabase authentication
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Login failed. No user returned.');
      }

      final profile = await ProfileRepository().getMe();

      final role = profile['role'] as String? ?? 'patient';

      // Hydrate Cubit so the rest of the app has profile data
      if (mounted) {
        context.read<RegistrationCubit>().updateProfile(
              RegistrationState.fromJson({
                ...profile,
                'email': user.email ?? email,
                'fullName': profile['full_name'] ?? '',
                'phoneNumber': profile['phone_number'] ?? '',
                'pharmacyName': profile['pharmacy_name'] ?? '',
                'pharmacyId': profile['pharmacy_id'] ?? '',
                'licenseNumber': profile['license_number'] ?? '',
              }),
            );
      }

      if (mounted) {
        if (role == 'patient') {
          context.go('/patient/home');
        } else if (role == 'provider') {
          context.go('/provider/dashboard');
        } else {
          context.go('/pharmacy/dashboard');
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      // Login failure with Supabase error
      setState(() {
        _failedAttempts++;
      });

      // Translate Supabase error codes to friendly messages
      String friendlyMessage;
      final rawMsg = e.message.toLowerCase();
      if (rawMsg.contains('email not confirmed')) {
        friendlyMessage =
            'Your account exists, but your email has not been confirmed. Please check your inbox and spam folder.';
      } else if (rawMsg.contains('invalid login credentials') ||
          rawMsg.contains('invalid email or password')) {
        // Supabase returns the same error for bad email OR bad password for security.
        // We show a generic but friendly message.
        friendlyMessage =
            'Account not found or incorrect password. Please check your details.';
      } else if (rawMsg.contains('too many requests') ||
          rawMsg.contains('rate limit')) {
        friendlyMessage =
            'Too many attempts. Please wait a moment and try again.';
      } else {
        friendlyMessage = e.message.isNotEmpty
            ? e.message
            : 'Login failed. Please try again.';
      }

      if (_failedAttempts >= 5) {
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Too many failed attempts. Please wait 30 seconds.'),
            backgroundColor: AppColors.statusBad,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMessage),
            backgroundColor: AppColors.statusBad,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: AppColors.statusBad,
        ),
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final messenger = ScaffoldMessenger.of(context);
    String? emailError;
    var isSending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> sendResetEmail() async {
            final email = resetEmailCtrl.text.trim();
            if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
              setDialogState(() {
                emailError = 'Enter a valid email address';
              });
              return;
            }

            setDialogState(() {
              emailError = null;
              isSending = true;
            });

            try {
              await Supabase.instance.client.auth.resetPasswordForEmail(
                email,
                redirectTo: 'stockalert://auth/reset-password',
              );
              await LocalDbService().write(
                'password_reset_pending',
                DateTime.now().toUtc().toIso8601String(),
              );
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text(
                    'Password reset link sent. Check your inbox and spam folder.',
                  ),
                  backgroundColor: AppColors.statusGood,
                ),
              );
            } on AuthException catch (error) {
              setDialogState(() {
                emailError = error.message;
                isSending = false;
              });
            } catch (_) {
              setDialogState(() {
                emailError =
                    'Unable to send the reset email. Please try again.';
                isSending = false;
              });
            }
          }

          return AlertDialog(
            title: const Text('Reset password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your account email and we’ll send you a password reset link.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !isSending,
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    errorText: emailError,
                  ),
                  onSubmitted: isSending ? null : (_) => sendResetEmail(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    isSending ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSending ? null : sendResetEmail,
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send reset link'),
              ),
            ],
          );
        },
      ),
    );
    resetEmailCtrl.dispose();
  }

  Future<void> _handleBiometricLogin() async {
    if (!_biometricsEnabled) return;
    final authenticated = await LocalAuthentication().authenticate(
      localizedReason: 'Authenticate to open StockAlert',
      options: const AuthenticationOptions(biometricOnly: true),
    );
    if (!authenticated || !mounted) return;
    if (Supabase.instance.client.auth.currentSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your saved session expired. Use your password.'),
          backgroundColor: AppColors.statusWarning,
        ),
      );
      return;
    }
    final profile = await ProfileRepository().getMe();
    if (!mounted) return;
    final role = profile['role'] as String? ?? 'patient';
    context.go(
      role == 'patient'
          ? '/patient/home'
          : role == 'provider'
              ? '/provider/dashboard'
              : '/pharmacy/dashboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCooldown = _cooldownSeconds > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Log In', style: AppTextStyles.subheading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome Back', style: AppTextStyles.heading),
            const SizedBox(height: 6),
            Text(
              'Enter your email and password or use biometrics to continue.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 32),
            const _FieldLabel('Email Address', isRequired: true),
            _AppTextField(
              hint: 'james.mensah@gmail.com',
              controller: _emailCtrl,
              errorText: _emailError,
              onChanged: (val) => _validateField('email', val),
            ),
            const _FieldLabel('Password', isRequired: true),
            _AppTextField(
              hint: '••••••••••••',
              obscureText: _obscurePassword,
              icon: _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              onIconTap: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              controller: _passwordCtrl,
              errorText: _passwordError,
              onChanged: (val) => _validateField('password', val),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text('Forgot password?'),
              ),
            ),
            if (isCooldown)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Too many failed login attempts. Please try again in $_cooldownSeconds seconds.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.statusBad,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCooldown ? null : _handleLogin,
                child: const Text('Log In'),
              ),
            ),
            if (_biometricsEnabled) ...[
              const SizedBox(height: 24),
              Center(
                child: Text('OR',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: isCooldown ? null : _handleBiometricLogin,
                  icon: const Icon(Icons.fingerprint, size: 24),
                  label: const Text('Log in with Biometrics'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  const _FieldLabel(this.text, {this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: RichText(
        text: TextSpan(
          text: text,
          style: AppTextStyles.label,
          children: [
            if (isRequired)
              TextSpan(
                text: ' (Required)',
                style: AppTextStyles.body
                    .copyWith(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppTextField extends StatefulWidget {
  final String hint;
  final IconData? icon;
  final bool obscureText;
  final VoidCallback? onIconTap;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _AppTextField({
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.onIconTap,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  @override
  State<_AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<_AppTextField> {
  bool _touched = false;

  @override
  Widget build(BuildContext context) {
    final showError = _touched && widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) {
              setState(() {
                _touched = true;
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: showError ? AppColors.statusBad : AppColors.hairline,
                width: showError ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              style: AppTextStyles.subheading,
              onChanged: (val) {
                if (widget.onChanged != null) {
                  widget.onChanged!(val);
                }
              },
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTextStyles.body,
                border: InputBorder.none,
                suffixIcon: widget.icon == null
                    ? null
                    : IconButton(
                        icon: Icon(widget.icon,
                            color: AppColors.textSecondary, size: 20),
                        onPressed: widget.onIconTap,
                      ),
              ),
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              widget.errorText!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.statusBad,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          const SizedBox(height: 8),
      ],
    );
  }
}

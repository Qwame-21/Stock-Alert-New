import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/storage/local_db_service.dart';
import '../../../../core/theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSaving = false;
  bool _isCheckingRecovery = true;
  bool _hasRecoverySession = false;
  String? _error;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _recoveryTimeout;

  @override
  void initState() {
    super.initState();
    _hasRecoverySession = Supabase.instance.client.auth.currentSession != null;
    _isCheckingRecovery = !_hasRecoverySession;

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
      final hasSession = authState.session != null ||
          Supabase.instance.client.auth.currentSession != null;
      if (!mounted) return;
      if (hasSession) {
        setState(() {
          _hasRecoverySession = true;
          _isCheckingRecovery = false;
        });
      } else if (authState.event == AuthChangeEvent.signedOut) {
        setState(() {
          _hasRecoverySession = false;
          _isCheckingRecovery = false;
        });
      }
    });

    if (_isCheckingRecovery) {
      _recoveryTimeout = Timer(const Duration(seconds: 8), () {
        if (!mounted || _hasRecoverySession) return;
        setState(() => _isCheckingRecovery = false);
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _recoveryTimeout?.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;

    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (password != confirmation) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _error = null;
      _isSaving = true;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      await LocalDbService().delete('password_reset_pending');
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {
        // Supabase clears the local session before attempting server logout.
        // Continue to login even if the remote revocation request fails.
      }
      if (!mounted) return;
      context.go(
        '/login',
        extra: {
          'expiredMessage':
              'Password updated successfully. Log in with your new password.',
        },
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to update your password. Request a new reset link.';
        _isSaving = false;
      });
    }
  }

  Future<void> _returnToLogin() async {
    await LocalDbService().delete('password_reset_pending');
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create new password'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset your password', style: AppTextStyles.heading),
            const SizedBox(height: 8),
            Text(
              _isCheckingRecovery
                  ? 'Verifying your password reset link…'
                  : _hasRecoverySession
                      ? 'Choose a strong password for your StockAlert account.'
                      : 'This reset link is invalid or has expired. Request a new link from the login screen.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 28),
            if (_isCheckingRecovery)
              const Center(child: CircularProgressIndicator())
            else if (_hasRecoverySession) ...[
              Text(
                'Use at least 8 characters. For better security, include uppercase and lowercase letters, a number, and a symbol.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enabled: !_isSaving,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmation,
                enabled: !_isSaving,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscureConfirmation = !_obscureConfirmation,
                    ),
                    icon: Icon(
                      _obscureConfirmation
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                onSubmitted: _isSaving ? null : (_) => _savePassword(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.statusBad,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePassword,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save new password'),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _returnToLogin,
                  child: const Text('Return to login'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

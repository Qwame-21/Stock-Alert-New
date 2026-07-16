import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/presentation/controllers/registration_cubit.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _validateField(String fieldName, String value) {
    setState(() {
      final state = context.read<RegistrationCubit>().state;
      final savedPassword = state.password.isNotEmpty ? state.password : 'password123';

      if (fieldName == 'current') {
        if (value.isEmpty) {
          _currentError = 'Current password is required';
        } else if (value != savedPassword) {
          _currentError = 'Incorrect current password';
        } else {
          _currentError = null;
        }
      } else if (fieldName == 'new') {
        if (value.isEmpty) {
          _newError = 'New password is required';
        } else if (value.length < 8) {
          _newError = 'New password must be at least 8 characters';
        } else if (value == _currentPasswordCtrl.text) {
          _newError = 'New password cannot be the same as current password';
        } else {
          _newError = null;
        }
        // Re-validate confirmation if it's already filled
        if (_confirmPasswordCtrl.text.isNotEmpty) {
          _validateField('confirm', _confirmPasswordCtrl.text);
        }
      } else if (fieldName == 'confirm') {
        if (value.isEmpty) {
          _confirmError = 'Confirm password is required';
        } else if (value != _newPasswordCtrl.text) {
          _confirmError = 'Passwords do not match';
        } else {
          _confirmError = null;
        }
      }
    });
  }

  Future<void> _handleSave() async {
    final current = _currentPasswordCtrl.text;
    final newPass = _newPasswordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    _validateField('current', current);
    _validateField('new', newPass);
    _validateField('confirm', confirm);

    if (_currentError != null || _newError != null || _confirmError != null) return;

    try {
      // Update password via Supabase Auth
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );

      // Also update the in-memory Cubit state (for UI display only, never persisted)
      final cubit = context.read<RegistrationCubit>();
      cubit.updatePassword(newPass);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
        context.pop();
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.statusBad,
          ),
        );
      }
    }
  }

  bool _isFormValid() {
    return _currentPasswordCtrl.text.isNotEmpty &&
        _newPasswordCtrl.text.isNotEmpty &&
        _confirmPasswordCtrl.text.isNotEmpty &&
        _currentError == null &&
        _newError == null &&
        _confirmError == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Change Password', style: AppTextStyles.subheading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: ListenableBuilder(
          listenable: Listenable.merge([
            _currentPasswordCtrl,
            _newPasswordCtrl,
            _confirmPasswordCtrl,
          ]),
          builder: (context, _) {
            final isValid = _isFormValid();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Update Password', style: AppTextStyles.heading),
                const SizedBox(height: 6),
                Text(
                  'Choose a strong password to secure your personal health details.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 32),

                const _FieldLabel('Current Password', isRequired: true),
                _AppTextField(
                  hint: '••••••••••••',
                  obscureText: _obscureCurrent,
                  icon: _obscureCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onIconTap: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  controller: _currentPasswordCtrl,
                  errorText: _currentError,
                  onChanged: (val) => _validateField('current', val),
                ),

                const _FieldLabel('New Password', isRequired: true),
                _AppTextField(
                  hint: '••••••••••••',
                  obscureText: _obscureNew,
                  icon: _obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onIconTap: () =>
                      setState(() => _obscureNew = !_obscureNew),
                  controller: _newPasswordCtrl,
                  errorText: _newError,
                  onChanged: (val) => _validateField('new', val),
                ),

                const _FieldLabel('Confirm New Password', isRequired: true),
                _AppTextField(
                  hint: '••••••••••••',
                  obscureText: _obscureConfirm,
                  icon: _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onIconTap: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  controller: _confirmPasswordCtrl,
                  errorText: _confirmError,
                  onChanged: (val) => _validateField('confirm', val),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isValid ? _handleSave : null,
                    child: const Text('Update Password'),
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
                style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
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
                        icon: Icon(widget.icon, color: AppColors.textSecondary, size: 20),
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

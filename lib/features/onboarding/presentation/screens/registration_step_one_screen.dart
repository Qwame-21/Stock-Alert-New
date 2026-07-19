import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/registration_cubit.dart';

class RegistrationStepOneScreen extends StatefulWidget {
  const RegistrationStepOneScreen({super.key});

  @override
  State<RegistrationStepOneScreen> createState() =>
      _RegistrationStepOneScreenState();
}

class _RegistrationStepOneScreenState extends State<RegistrationStepOneScreen> {
  bool _obscurePassword = true;

  // Controllers for Patient
  final _fullNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // Selected country code
  String _selectedCountryCode = '+233'; // Default to Ghana
  final List<Map<String, String>> _countries = const [
    {'code': '+233', 'flag': '🇬🇭', 'name': 'Ghana'},
    {'code': '+234', 'flag': '🇳🇬', 'name': 'Nigeria'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'UK'},
    {'code': '+254', 'flag': '🇰🇪', 'name': 'Kenya'},
  ];

  // Controllers for Pharmacy
  final _pharmacyNameCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _authorityCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();

  // Error texts for Patient
  String? _fullNameError;
  String? _dobError;
  String? _genderError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Error texts for Pharmacy
  String? _pharmacyNameError;
  String? _licenseError;
  String? _authorityError;
  String? _locationError;
  String? _hoursError;

  @override
  void initState() {
    super.initState();
    // Pre-populate controllers from current Cubit state if any
    final state = context.read<RegistrationCubit>().state;
    _fullNameCtrl.text = state.fullName;
    _dobCtrl.text = state.dob;
    _genderCtrl.text = state.gender.isNotEmpty ? state.gender : 'Male';

    // Parse phone country code if already set
    if (state.phoneNumber.isNotEmpty) {
      final match = _countries.firstWhere(
        (c) => state.phoneNumber.startsWith(c['code']!),
        orElse: () => {'code': ''},
      );
      if (match['code']!.isNotEmpty) {
        _selectedCountryCode = match['code']!;
        _phoneCtrl.text =
            state.phoneNumber.replaceFirst(_selectedCountryCode, '').trim();
      } else {
        _phoneCtrl.text = state.phoneNumber;
      }
    }

    _emailCtrl.text = state.email;
    _passwordCtrl.text = state.password;
    _confirmPasswordCtrl.text = state.password;

    _pharmacyNameCtrl.text = state.pharmacyName;
    _licenseCtrl.text = state.licenseNumber;
    _authorityCtrl.text = state.registrationAuthority;
    _locationCtrl.text = state.location;
    _hoursCtrl.text = state.operatingHours;
    _supplierCtrl.text = state.supplierPreference;

    // Run initial validation checks so errors update correctly
    _validateAll(state.role == 'patient');
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _dobCtrl.dispose();
    _genderCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();

    _pharmacyNameCtrl.dispose();
    _licenseCtrl.dispose();
    _authorityCtrl.dispose();
    _locationCtrl.dispose();
    _hoursCtrl.dispose();
    _supplierCtrl.dispose();
    super.dispose();
  }

  void _validateAll(bool isPatient) {
    if (isPatient) {
      _validateField('name', _fullNameCtrl.text);
      _validateField('dob', _dobCtrl.text);
      _validateField('gender', _genderCtrl.text);
      _validateField('phone', _phoneCtrl.text);
      _validateField('email', _emailCtrl.text);
      _validateField('password', _passwordCtrl.text);
      _validateField('confirmPassword', _confirmPasswordCtrl.text);
    } else {
      _validateField('phone', _phoneCtrl.text);
      _validateField('email', _emailCtrl.text);
      _validateField('password', _passwordCtrl.text);
      _validateField('confirmPassword', _confirmPasswordCtrl.text);
      _validateField('pharmacyName', _pharmacyNameCtrl.text);
      _validateField('license', _licenseCtrl.text);
      _validateField('authority', _authorityCtrl.text);
      _validateField('location', _locationCtrl.text);
      _validateField('hours', _hoursCtrl.text);
    }
  }

  void _validateField(String fieldName, String value) {
    setState(() {
      switch (fieldName) {
        case 'name':
          _fullNameError =
              value.trim().isEmpty ? 'Full Name is required' : null;
          break;
        case 'dob':
          _dobError = value.trim().isEmpty ? 'Date of birth is required' : null;
          break;
        case 'gender':
          _genderError = value.trim().isEmpty ? 'Gender is required' : null;
          break;
        case 'phone':
          if (value.trim().isEmpty) {
            _phoneError = 'Phone Number is required';
          } else if (value.trim().length < 7) {
            _phoneError = 'Enter a valid phone number';
          } else {
            _phoneError = null;
          }
          break;
        case 'email':
          if (value.trim().isEmpty) {
            _emailError = 'Email Address is required';
          } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
              .hasMatch(value)) {
            _emailError = 'Enter a valid email address';
          } else {
            _emailError = null;
          }
          break;
        case 'password':
          if (value.isEmpty) {
            _passwordError = 'Password is required';
          } else if (value.length < 8) {
            _passwordError = 'Password must be at least 8 characters';
          } else {
            _passwordError = null;
          }
          // Re-validate confirm password if it's not empty
          if (_confirmPasswordCtrl.text.isNotEmpty) {
            _confirmPasswordError = _confirmPasswordCtrl.text != value
                ? 'Passwords do not match'
                : null;
          }
          break;
        case 'confirmPassword':
          if (value.isEmpty) {
            _confirmPasswordError = 'Please confirm your password';
          } else if (value != _passwordCtrl.text) {
            _confirmPasswordError = 'Passwords do not match';
          } else {
            _confirmPasswordError = null;
          }
          break;
        case 'pharmacyName':
          _pharmacyNameError =
              value.trim().isEmpty ? 'Pharmacy Name is required' : null;
          break;
        case 'license':
          _licenseError =
              value.trim().isEmpty ? 'License Number is required' : null;
          break;
        case 'authority':
          _authorityError = value.trim().isEmpty
              ? 'Registration Authority is required'
              : null;
          break;
        case 'location':
          _locationError =
              value.trim().isEmpty ? 'Location / Address is required' : null;
          break;
        case 'hours':
          _hoursError =
              value.trim().isEmpty ? 'Operating Hours are required' : null;
          break;
      }
    });
  }

  void _onContinue(bool isPatient) async {
    final cubit = context.read<RegistrationCubit>();
    if (isPatient) {
      cubit.updatePatientInfo(
        fullName: _fullNameCtrl.text,
        dob: _dobCtrl.text,
        gender: _genderCtrl.text,
        phoneNumber: '$_selectedCountryCode ${_phoneCtrl.text.trim()}',
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
    } else {
      cubit.updateAccountCredentials(
        email: _emailCtrl.text.trim(),
        phoneNumber: '$_selectedCountryCode ${_phoneCtrl.text.trim()}',
        password: _passwordCtrl.text,
      );
      cubit.updatePharmacyInfo(
        pharmacyName: _pharmacyNameCtrl.text,
        licenseNumber: _licenseCtrl.text,
        registrationAuthority: _authorityCtrl.text,
        location: _locationCtrl.text,
        operatingHours: _hoursCtrl.text,
        supplierPreference: _supplierCtrl.text,
      );
    }
    // Save registration state to DB at step 1
    await cubit.saveProgress(1);

    if (mounted) {
      context.push('/register/2');
    }
  }

  bool _isFormValid(bool isPatient) {
    if (isPatient) {
      return _fullNameCtrl.text.isNotEmpty &&
          _dobCtrl.text.isNotEmpty &&
          _genderCtrl.text.isNotEmpty &&
          _phoneCtrl.text.isNotEmpty &&
          _emailCtrl.text.isNotEmpty &&
          _passwordCtrl.text.isNotEmpty &&
          _confirmPasswordCtrl.text.isNotEmpty &&
          _fullNameError == null &&
          _dobError == null &&
          _genderError == null &&
          _phoneError == null &&
          _emailError == null &&
          _passwordError == null &&
          _confirmPasswordError == null;
    } else {
      return _pharmacyNameCtrl.text.isNotEmpty &&
          _phoneCtrl.text.isNotEmpty &&
          _emailCtrl.text.isNotEmpty &&
          _passwordCtrl.text.isNotEmpty &&
          _confirmPasswordCtrl.text.isNotEmpty &&
          _licenseCtrl.text.isNotEmpty &&
          _authorityCtrl.text.isNotEmpty &&
          _locationCtrl.text.isNotEmpty &&
          _hoursCtrl.text.isNotEmpty &&
          _pharmacyNameError == null &&
          _licenseError == null &&
          _authorityError == null &&
          _locationError == null &&
          _hoursError == null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationCubit, RegistrationState>(
      builder: (context, state) {
        final isPatient = state.role == 'patient';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/choose-role');
                }
              },
            ),
            title: Text('1 of 4', style: AppTextStyles.label),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListenableBuilder(
              listenable: Listenable.merge([
                _fullNameCtrl,
                _dobCtrl,
                _genderCtrl,
                _phoneCtrl,
                _emailCtrl,
                _passwordCtrl,
                _confirmPasswordCtrl,
                _pharmacyNameCtrl,
                _licenseCtrl,
                _authorityCtrl,
                _locationCtrl,
                _hoursCtrl,
                _supplierCtrl,
              ]),
              builder: (context, _) {
                final isValid = _isFormValid(isPatient);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPatient ? 'Your Information' : 'Pharmacy Information',
                      style: AppTextStyles.heading,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isPatient
                          ? "Let's start with some basic details."
                          : "Enter details for your community pharmacy.",
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 24),
                    if (isPatient) ...[
                      const _FieldLabel('Full Name', isRequired: true),
                      _AppTextField(
                        hint: 'James Mensah',
                        controller: _fullNameCtrl,
                        errorText: _fullNameError,
                        textInputAction: TextInputAction.next,
                        onChanged: (val) => _validateField('name', val),
                      ),
                      const _FieldLabel('Date of Birth', isRequired: true),
                      _AppTextField(
                        hint: 'YYYY-MM-DD',
                        icon: Icons.calendar_today_outlined,
                        controller: _dobCtrl,
                        errorText: _dobError,
                        readOnly: true,
                        onTap: () async {
                          // Make it easy to select DOB by starting at 18 years ago (adult default)
                          final eighteenYearsAgo = DateTime.now()
                              .subtract(const Duration(days: 365 * 18));
                          final initialDate =
                              DateTime.tryParse(_dobCtrl.text) ??
                                  eighteenYearsAgo;
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            final dateStr = picked.toString().split(' ').first;
                            _dobCtrl.text = dateStr;
                            _validateField('dob', dateStr);
                          }
                        },
                        onChanged: (val) => _validateField('dob', val),
                      ),
                      const _FieldLabel('Gender', isRequired: true),
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.hairline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            initialValue: _genderCtrl.text.isNotEmpty
                                ? _genderCtrl.text
                                : 'Male',
                            items: [
                              DropdownMenuItem(
                                  value: 'Male',
                                  child: Text('Male',
                                      style: AppTextStyles.subheading)),
                              DropdownMenuItem(
                                  value: 'Female',
                                  child: Text('Female',
                                      style: AppTextStyles.subheading)),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                _genderCtrl.text = val;
                                _validateField('gender', val);
                              }
                            },
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      if (_genderError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(_genderError!,
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.statusBad, fontSize: 12)),
                        ),
                      const _FieldLabel('Phone Number', isRequired: true),
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.hairline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCountryCode,
                                items: _countries.map((country) {
                                  return DropdownMenuItem(
                                    value: country['code'],
                                    child: Text(
                                      '${country['flag']} ${country['code']}',
                                      style: AppTextStyles.subheading,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedCountryCode = val;
                                    });
                                  }
                                },
                              ),
                            ),
                            const VerticalDivider(
                                width: 16,
                                thickness: 1,
                                color: AppColors.hairline),
                            Expanded(
                              child: TextField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                style: AppTextStyles.subheading,
                                onChanged: (val) =>
                                    _validateField('phone', val),
                                decoration: InputDecoration(
                                  hintText: '24 123 4567',
                                  hintStyle: AppTextStyles.body,
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_phoneError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(_phoneError!,
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.statusBad, fontSize: 12)),
                        ),
                      const _FieldLabel('Email Address', isRequired: true),
                      _AppTextField(
                        hint: 'james.mensah@gmail.com',
                        controller: _emailCtrl,
                        errorText: _emailError,
                        textInputAction: TextInputAction.next,
                        onChanged: (val) => _validateField('email', val),
                      ),
                      const _FieldLabel('Password', isRequired: true),
                      _AppTextField(
                        hint: '••••••••••••',
                        obscureText: _obscurePassword,
                        icon: _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        onIconTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        controller: _passwordCtrl,
                        errorText: _passwordError,
                        textInputAction: TextInputAction.next,
                        onChanged: (val) => _validateField('password', val),
                      ),
                      const _FieldLabel('Confirm Password', isRequired: true),
                      _AppTextField(
                        hint: '••••••••••••',
                        obscureText: _obscurePassword,
                        icon: _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        onIconTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        controller: _confirmPasswordCtrl,
                        errorText: _confirmPasswordError,
                        textInputAction: TextInputAction.done,
                        onChanged: (val) =>
                            _validateField('confirmPassword', val),
                      ),
                    ] else ...[
                      const _FieldLabel('Pharmacy Name', isRequired: true),
                      _AppTextField(
                        hint: 'Green Pharmacy',
                        controller: _pharmacyNameCtrl,
                        errorText: _pharmacyNameError,
                        textInputAction: TextInputAction.next,
                        onChanged: (val) => _validateField('pharmacyName', val),
                      ),
                      const _FieldLabel('License Number', isRequired: true),
                      _AppTextField(
                        hint: 'PHA-90210-X',
                        controller: _licenseCtrl,
                        errorText: _licenseError,
                        textInputAction: TextInputAction.next,
                        onChanged: (val) => _validateField('license', val),
                      ),
                      const _FieldLabel('Registration Authority',
                          isRequired: true),
                      _AppTextField(
                        hint: 'Pharmacy Council of Ghana',
                        controller: _authorityCtrl,
                        errorText: _authorityError,
                        textInputAction: TextInputAction.next,
                        onChanged: (val) => _validateField('authority', val),
                      ),
                      const _FieldLabel('Location / Address', isRequired: true),
                      _AppTextField(
                        hint: 'Spintex Road, Accra',
                        controller: _locationCtrl,
                        errorText: _locationError,
                        textInputAction: TextInputAction.next,
                        onChanged: (val) => _validateField('location', val),
                      ),
                      const _FieldLabel('Operating Hours', isRequired: true),
                      _AppTextField(
                        hint: '8:00 AM - 9:00 PM',
                        controller: _hoursCtrl,
                        errorText: _hoursError,
                        textInputAction: TextInputAction.next,
                        onChanged: (val) => _validateField('hours', val),
                      ),
                      const _FieldLabel('Supplier Preference',
                          isRequired: false),
                      _AppTextField(
                        hint: 'e.g. Standard Wholesales Ltd',
                        controller: _supplierCtrl,
                        textInputAction: TextInputAction.done,
                      ),
                      const _FieldLabel('Business Phone', isRequired: true),
                      _AppTextField(
                        hint: '+233 24 123 4567',
                        controller: _phoneCtrl,
                        errorText: _phoneError,
                        onChanged: (val) => _validateField('phone', val),
                      ),
                      const _FieldLabel('Account Email', isRequired: true),
                      _AppTextField(
                        hint: 'owner@pharmacy.com',
                        controller: _emailCtrl,
                        errorText: _emailError,
                        onChanged: (val) => _validateField('email', val),
                      ),
                      const _FieldLabel('Password', isRequired: true),
                      _AppTextField(
                        hint: '••••••••',
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        errorText: _passwordError,
                        onChanged: (val) => _validateField('password', val),
                      ),
                      const _FieldLabel('Confirm Password', isRequired: true),
                      _AppTextField(
                        hint: '••••••••',
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscurePassword,
                        errorText: _confirmPasswordError,
                        onChanged: (val) =>
                            _validateField('confirmPassword', val),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            isValid ? () => _onContinue(isPatient) : null,
                        child: const Text('Continue'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        );
      },
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
              )
            else
              TextSpan(
                text: ' (Optional)',
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
  final TextInputAction? textInputAction;
  final bool readOnly;
  final VoidCallback? onTap;
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
    this.textInputAction,
    this.readOnly = false,
    this.onTap,
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
              textInputAction: widget.textInputAction,
              readOnly: widget.readOnly,
              onTap: widget.onTap,
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

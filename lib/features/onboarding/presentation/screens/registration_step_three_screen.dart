import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/registration_cubit.dart';

class RegistrationStepThreeScreen extends StatefulWidget {
  const RegistrationStepThreeScreen({super.key});

  @override
  State<RegistrationStepThreeScreen> createState() => _RegistrationStepThreeScreenState();
}

class _RegistrationStepThreeScreenState extends State<RegistrationStepThreeScreen> {
  final _allergyController = TextEditingController();
  final _conditionController = TextEditingController();
  final _medicationController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyEmailController = TextEditingController();

  String _bloodGroup = 'A+';
  final List<String> _allergies = [];
  final List<String> _conditions = [];

  // Validation errors
  String? _emergencyNameError;
  String? _emergencyPhoneError;
  String? _emergencyEmailError;

  @override
  void initState() {
    super.initState();
    // Pre-populate fields on resume
    final state = context.read<RegistrationCubit>().state;
    _bloodGroup = state.bloodGroup.isNotEmpty ? state.bloodGroup : 'A+';
    _allergies.addAll(state.knownAllergies);
    _conditions.addAll(state.chronicConditions);
    _medicationController.text = state.currentMedication;
    _emergencyNameController.text = state.emergencyContactName;
    _emergencyPhoneController.text = state.emergencyContactPhone;
    _emergencyEmailController.text = state.emergencyContactEmail;

    _validateFields();
  }

  @override
  void dispose() {
    _allergyController.dispose();
    _conditionController.dispose();
    _medicationController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyEmailController.dispose();
    super.dispose();
  }

  void _validateFields() {
    setState(() {
      final name = _emergencyNameController.text.trim();
      final phone = _emergencyPhoneController.text.trim();
      final email = _emergencyEmailController.text.trim();

      _emergencyNameError = name.isEmpty ? 'Emergency contact name is required' : null;
      if (phone.isEmpty) {
        _emergencyPhoneError = 'Emergency contact phone is required';
      } else if (phone.length < 8) {
        _emergencyPhoneError = 'Enter a valid phone number';
      } else {
        _emergencyPhoneError = null;
      }

      if (email.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emergencyEmailError = 'Enter a valid email address';
      } else {
        _emergencyEmailError = null;
      }
    });
  }

  void _addAllergy([String? val]) {
    final allergy = val ?? _allergyController.text.trim();
    if (allergy.isNotEmpty) {
      setState(() {
        if (allergy == 'No Allergies') {
          _allergies.clear();
          _allergies.add('No Allergies');
        } else {
          _allergies.remove('No Allergies');
          if (!_allergies.contains(allergy)) {
            _allergies.add(allergy);
          }
        }
        _allergyController.clear();
      });
      _saveState();
    }
  }

  void _addCondition() {
    final val = _conditionController.text.trim();
    if (val.isNotEmpty && !_conditions.contains(val)) {
      setState(() {
        _conditions.add(val);
        _conditionController.clear();
      });
      _saveState();
    }
  }

  void _saveState() {
    context.read<RegistrationCubit>().updateHealthProfile(
      bloodGroup: _bloodGroup,
      knownAllergies: _allergies,
      chronicConditions: _conditions,
      currentMedication: _medicationController.text,
      emergencyContactName: _emergencyNameController.text,
      emergencyContactPhone: _emergencyPhoneController.text,
      emergencyContactEmail: _emergencyEmailController.text,
    );
  }

  bool _isFormValid() {
    return _allergies.isNotEmpty &&
        _emergencyNameController.text.trim().isNotEmpty &&
        _emergencyPhoneController.text.trim().isNotEmpty &&
        _emergencyNameError == null &&
        _emergencyPhoneError == null &&
        _emergencyEmailError == null;
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _isFormValid();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('3 of 4', style: AppTextStyles.label),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Health Profile', style: AppTextStyles.heading),
            const SizedBox(height: 6),
            Text(
              'Help pharmacies check for drug interactions and know who to contact in an emergency.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            
            // Blood Group Dropdown
            const _FieldLabel('Blood Group', isRequired: false),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hairline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _bloodGroup,
                  isExpanded: true,
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((bg) => DropdownMenuItem(
                            value: bg,
                            child: Text(bg, style: AppTextStyles.subheading),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _bloodGroup = val);
                      _saveState();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Known Allergies (Required Chip Input)
            const _FieldLabel('Known Allergies (Food, Drug, or Environmental)', isRequired: true),
            
            // Professional selection suggestions
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('No Allergies'),
                    onPressed: () => _addAllergy('No Allergies'),
                    backgroundColor: _allergies.contains('No Allergies') ? AppColors.accent.withOpacity(0.2) : null,
                  ),
                  ActionChip(
                    label: const Text('Peanuts'),
                    onPressed: () => _addAllergy('Peanuts'),
                  ),
                  ActionChip(
                    label: const Text('Penicillin'),
                    onPressed: () => _addAllergy('Penicillin'),
                  ),
                  ActionChip(
                    label: const Text('Sulfa Drugs'),
                    onPressed: () => _addAllergy('Sulfa Drugs'),
                  ),
                  ActionChip(
                    label: const Text('Lactose'),
                    onPressed: () => _addAllergy('Lactose'),
                  ),
                ],
              ),
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.hairline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _allergyController,
                      style: AppTextStyles.subheading,
                      onSubmitted: (_) => _addAllergy(),
                      decoration: InputDecoration(
                        hintText: 'Type other allergy...',
                        hintStyle: AppTextStyles.body,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _addAllergy,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _allergies
                  .map((alg) => InputChip(
                        label: Text(alg),
                        onDeleted: () {
                          setState(() => _allergies.remove(alg));
                          _saveState();
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Chronic Conditions
            const _FieldLabel('Chronic Conditions', isRequired: false),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.hairline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _conditionController,
                      style: AppTextStyles.subheading,
                      onSubmitted: (_) => _addCondition(),
                      decoration: InputDecoration(
                        hintText: 'e.g. Asthma, Hypertension...',
                        hintStyle: AppTextStyles.body,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _addCondition,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _conditions
                  .map((cond) => InputChip(
                        label: Text(cond),
                        onDeleted: () {
                          setState(() => _conditions.remove(cond));
                          _saveState();
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Current Medication
            const _FieldLabel('Current Medication', isRequired: false),
            _AppTextField(
              hint: 'e.g. Cetirizine 10mg daily',
              controller: _medicationController,
              onChanged: (_) => _saveState(),
            ),

            // Emergency Contact Name
            const _FieldLabel('Emergency Contact Name', isRequired: true),
            _AppTextField(
              hint: 'e.g. Sarah Mensah',
              controller: _emergencyNameController,
              errorText: _emergencyNameError,
              onChanged: (_) {
                _validateFields();
                _saveState();
              },
            ),

            // Emergency Contact Phone
            const _FieldLabel('Emergency Contact Phone', isRequired: true),
            _AppTextField(
              hint: 'e.g. +233 24 999 8888',
              controller: _emergencyPhoneController,
              errorText: _emergencyPhoneError,
              onChanged: (_) {
                _validateFields();
                _saveState();
              },
            ),

            // Emergency Contact Email
            const _FieldLabel('Emergency Contact Email', isRequired: false),
            _AppTextField(
              hint: 'e.g. sarah.mensah@gmail.com',
              controller: _emergencyEmailController,
              errorText: _emergencyEmailError,
              onChanged: (_) {
                _validateFields();
                _saveState();
              },
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isValid
                    ? () async {
                        _saveState();
                        final cubit = context.read<RegistrationCubit>();
                        // Save Step 3 progress
                        await cubit.saveProgress(3);

                        if (context.mounted) {
                          context.push('/register/4');
                        }
                      }
                    : null,
                child: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 32),
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
                style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
              )
            else
              TextSpan(
                text: ' (Optional)',
                style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;

  const _AppTextField({
    required this.hint,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final showError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
            controller: controller,
            style: AppTextStyles.subheading,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.body,
              border: InputBorder.none,
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              errorText!,
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

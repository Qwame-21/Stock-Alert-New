import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/top_notice.dart';
import '../../../onboarding/data/profile_repository.dart';

class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _RegistrationSection extends StatelessWidget {
  const _RegistrationSection({
    required this.number,
    required this.title,
    required this.description,
    required this.children,
  });

  final String number, title, description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Text(number,
                  style: AppTextStyles.label.copyWith(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.subheading),
                    Text(description, style: AppTextStyles.body),
                  ]),
            ),
          ]),
          const SizedBox(height: 18),
          ...children,
        ]),
      );
}

class _ProviderRegistrationScreenState
    extends State<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _specialty = TextEditingController();
  final _license = TextEditingController();
  final _authority = TextEditingController();
  final _experience = TextEditingController(text: '0');
  final _bio = TextEditingController();
  final _location = TextEditingController();
  String _mode = 'video';
  int _duration = 30;
  bool _loading = false;
  XFile? _profileImage;
  bool _policyAccepted = false;

  Future<void> _pickProfileImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (image != null && mounted) setState(() => _profileImage = image);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _password,
      _confirmPassword,
      _specialty,
      _license,
      _authority,
      _experience,
      _bio,
      _location,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileImage == null || !_policyAccepted) {
      showTopNotice(context,
          title: 'Complete your registration',
          message: _profileImage == null
              ? 'Add a clear professional profile photo to continue.'
              : 'Accept the Provider Code of Conduct to continue.',
          type: TopNoticeType.warning);
      return;
    }
    setState(() => _loading = true);
    try {
      var extension = _profileImage!.path.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        extension = 'jpg';
      }
      final photo = base64Encode(await _profileImage!.readAsBytes());
      final result = await ProfileRepository().register({
        'role': 'provider',
        'fullName': _name.text.trim(),
        'email': _email.text.trim().toLowerCase(),
        'phoneNumber': _phone.text.trim(),
        'password': _password.text,
        'specialty': _specialty.text.trim(),
        'professionalLicense': _license.text.trim(),
        'registrationAuthority': _authority.text.trim(),
        'yearsExperience': int.tryParse(_experience.text.trim()) ?? 0,
        if (_bio.text.trim().isNotEmpty) 'bio': _bio.text.trim(),
        'consultationMode': _mode,
        if (_location.text.trim().isNotEmpty) 'location': _location.text.trim(),
        'consultationDuration': _duration,
        'documentType': 'Professional License',
        'profileImageBase64': photo,
        'profileImageExtension': extension,
        'providerPolicyAccepted': true,
      });
      if (!mounted) return;
      final session = result['session'] as Map?;
      final refreshToken = session?['refreshToken'] as String?;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await Supabase.instance.client.auth.setSession(refreshToken);
      }
      if (!mounted) return;
      if (Supabase.instance.client.auth.currentSession != null) {
        context.go('/provider/dashboard');
      } else {
        context.go('/login', extra: {
          'expiredMessage':
              'Provider account created. Confirm your email, then sign in. Your profile must be verified before patients can book you.',
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultation provider registration')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Build your provider profile',
                        style: AppTextStyles.heading
                            .copyWith(color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                        'A clear, complete profile helps patients choose with confidence.',
                        style:
                            AppTextStyles.body.copyWith(color: Colors.white70)),
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(
                        value: .25,
                        color: Colors.white,
                        backgroundColor: Colors.white24),
                  ]),
            ),
            const SizedBox(height: 16),
            _RegistrationSection(
              number: '01',
              title: 'Professional identity',
              description:
                  'The profile patients will see when choosing a provider.',
              children: [
                Center(
                  child: InkWell(
                    onTap: _loading ? null : _pickProfileImage,
                    borderRadius: BorderRadius.circular(60),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.accent.withValues(alpha: .1),
                      backgroundImage: _profileImage == null
                          ? null
                          : FileImage(File(_profileImage!.path)),
                      child: _profileImage == null
                          ? const Icon(Icons.add_a_photo_outlined,
                              color: AppColors.accent, size: 30)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Professional photo (required)',
                    textAlign: TextAlign.center, style: AppTextStyles.label),
                const SizedBox(height: 20),
                _field(_name, 'Full professional name'),
                _field(_phone, 'Phone number',
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        (value ?? '').replaceAll(RegExp(r'\D'), '').length < 7
                            ? 'Enter a valid phone number'
                            : null),
              ],
            ),
            const SizedBox(height: 14),
            _RegistrationSection(
              number: '02',
              title: 'Account security',
              description: 'Use an email you can access and a secure password.',
              children: [
                _field(_email, 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value?.trim() ?? '')
                        ? 'Enter a valid email address'
                        : null),
                _field(_password, 'Password',
                    obscure: true,
                    validator: (value) => (value?.length ?? 0) < 8
                        ? 'Use at least 8 characters'
                        : null),
                _field(_confirmPassword, 'Confirm password',
                    obscure: true,
                    validator: (value) => value != _password.text
                        ? 'Passwords do not match'
                        : null),
              ],
            ),
            const SizedBox(height: 14),
            _RegistrationSection(
              number: '03',
              title: 'Credentials',
              description:
                  'Information used to verify your clinical background.',
              children: [
                _field(_specialty, 'Specialty, e.g. General Practice'),
                _field(_license, 'Professional license number'),
                _field(_authority, 'Registration authority'),
                _field(_experience, 'Years of experience',
                    keyboardType: TextInputType.number),
                _field(_bio, 'Professional biography', maxLines: 4),
              ],
            ),
            const SizedBox(height: 14),
            _RegistrationSection(
              number: '04',
              title: 'Consultation setup',
              description: 'Set the initial way patients can book with you.',
              children: [
                _field(_location, 'Consultation location (if in-person)'),
                DropdownButtonFormField<String>(
                  initialValue: _mode,
                  decoration:
                      const InputDecoration(labelText: 'Consultation mode'),
                  items: const [
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                    DropdownMenuItem(
                        value: 'in_person', child: Text('In person')),
                    DropdownMenuItem(
                        value: 'both', child: Text('Video and in person')),
                  ],
                  onChanged: (value) => setState(() => _mode = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _duration,
                  decoration: const InputDecoration(
                      labelText: 'Default appointment length'),
                  items: const [15, 20, 30, 45, 60]
                      .map((value) => DropdownMenuItem(
                          value: value, child: Text('$value minutes')))
                      .toList(),
                  onChanged: (value) => setState(() => _duration = value!),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  Text('Provider Code of Conduct',
                      style: AppTextStyles.subheading),
                  const SizedBox(height: 6),
                  Text(
                    'I will protect patient privacy, communicate respectfully, provide only services within my verified qualifications, keep appointment information accurate, avoid discrimination, and escalate emergencies to appropriate local services.',
                    style: AppTextStyles.body,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _policyAccepted,
                    onChanged: _loading
                        ? null
                        : (value) =>
                            setState(() => _policyAccepted = value ?? false),
                    title: const Text('I accept and will follow this policy'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppColors.accent),
              child: Text(
                  _loading ? 'Creating account…' : 'Create provider account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator ?? _required,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

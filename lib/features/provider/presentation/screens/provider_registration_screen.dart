import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends State<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _specialty = TextEditingController();
  final _license = TextEditingController();
  final _authority = TextEditingController();
  final _experience = TextEditingController(text: '0');
  final _bio = TextEditingController();
  final _location = TextEditingController();
  String _mode = 'video';
  int _duration = 30;
  bool _loading = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _password,
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
    setState(() => _loading = true);
    try {
      await ApiClient.instance.post(
        '/api/v1/auth/register',
        authenticated: false,
        body: {
          'role': 'provider',
          'fullName': _name.text.trim(),
          'email': _email.text.trim().toLowerCase(),
          'phoneNumber': _phone.text.trim(),
          'password': _password.text,
          'specialty': _specialty.text.trim(),
          'professionalLicense': _license.text.trim(),
          'registrationAuthority': _authority.text.trim(),
          'yearsExperience': int.parse(_experience.text),
          if (_bio.text.trim().isNotEmpty) 'bio': _bio.text.trim(),
          'consultationMode': _mode,
          if (_location.text.trim().isNotEmpty)
            'location': _location.text.trim(),
          'consultationDuration': _duration,
          'documentType': 'Professional License',
        },
      );
      if (!mounted) return;
      context.go('/login', extra: {
        'expiredMessage':
            'Provider account created. Confirm your email, then sign in. Your profile must be verified before patients can book you.',
      });
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
            Text('Professional identity', style: AppTextStyles.heading),
            Text(
              'These details identify you to patients and support credential verification.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 20),
            _field(_name, 'Full professional name'),
            _field(_email, 'Email address'),
            _field(_phone, 'Phone number'),
            _field(_password, 'Password',
                obscure: true,
                validator: (value) => (value?.length ?? 0) < 8
                    ? 'Use at least 8 characters'
                    : null),
            _field(_specialty, 'Specialty, e.g. General Practice'),
            _field(_license, 'Professional license number'),
            _field(_authority, 'Registration authority'),
            _field(_experience, 'Years of experience',
                keyboardType: TextInputType.number),
            _field(_bio, 'Professional biography', maxLines: 4),
            _field(_location, 'Consultation location (if in-person)'),
            DropdownButtonFormField<String>(
              value: _mode,
              decoration: const InputDecoration(labelText: 'Consultation mode'),
              items: const [
                DropdownMenuItem(value: 'video', child: Text('Video')),
                DropdownMenuItem(value: 'in_person', child: Text('In person')),
                DropdownMenuItem(
                    value: 'both', child: Text('Video and in person')),
              ],
              onChanged: (value) => setState(() => _mode = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _duration,
              decoration: const InputDecoration(
                  labelText: 'Default appointment length'),
              items: const [15, 20, 30, 45, 60]
                  .map((value) => DropdownMenuItem(
                      value: value, child: Text('$value minutes')))
                  .toList(),
              onChanged: (value) => setState(() => _duration = value!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
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

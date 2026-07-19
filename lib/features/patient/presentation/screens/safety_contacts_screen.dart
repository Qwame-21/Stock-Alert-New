import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/storage/local_db_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/presentation/controllers/registration_cubit.dart';

class SafetyContactsScreen extends StatefulWidget {
  const SafetyContactsScreen({super.key});

  @override
  State<SafetyContactsScreen> createState() => _SafetyContactsScreenState();
}

class _SafetyContactsScreenState extends State<SafetyContactsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final registration = context.read<RegistrationCubit>().state;
    final raw = await LocalDbService().read('trusted_contacts');
    final name = await LocalDbService().read('trusted_contact_name');
    final phone = await LocalDbService().read('trusted_contact_phone');
    if (!mounted) return;
    if (raw != null) {
      _contacts = (jsonDecode(raw) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } else if ((name ?? registration.emergencyContactName).isNotEmpty) {
      _contacts = [
        {
          'name': name ?? registration.emergencyContactName,
          'phone': phone ?? registration.emergencyContactPhone,
          'relationship': 'Primary contact',
        }
      ];
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      final contact = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'relationship': 'Trusted contact',
      };
      _contacts.add(contact);
      await LocalDbService().write('trusted_contacts', jsonEncode(_contacts));
      _nameController.clear();
      _phoneController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trusted contact saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save contact: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _call(String phone) async {
    final opened = await launchUrl(
      Uri(scheme: 'tel', path: phone),
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calling is unavailable on this device.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety & trusted contacts')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text('Emergency contact', style: AppTextStyles.heading),
                    const SizedBox(height: 8),
                    Text(
                      'Add the people you trust in an urgent situation. StockAlert is not an emergency service.',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 20),
                    if (_contacts.isNotEmpty) ...[
                      Text('Your contacts', style: AppTextStyles.subheading),
                      const SizedBox(height: 10),
                      ..._contacts.asMap().entries.map((entry) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                  child: Icon(Icons.person_outline)),
                              title: Text(entry.value['name'] as String),
                              subtitle: Text(entry.value['phone'] as String),
                              onTap: () =>
                                  _call(entry.value['phone'] as String),
                              trailing: IconButton(
                                tooltip: 'Remove contact',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  setState(() => _contacts.removeAt(entry.key));
                                  await LocalDbService().write(
                                      'trusted_contacts',
                                      jsonEncode(_contacts));
                                },
                              ),
                            ),
                          )),
                      const SizedBox(height: 14),
                      Text('Add another contact',
                          style: AppTextStyles.subheading),
                      const SizedBox(height: 10),
                    ],
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Trusted contact name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 2
                              ? 'Enter the contact’s name'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        final digits =
                            (value ?? '').replaceAll(RegExp(r'\D'), '');
                        return digits.length < 7
                            ? 'Enter a valid phone number'
                            : null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving…' : 'Save trusted contact'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

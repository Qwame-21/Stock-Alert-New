import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_db_service.dart';
import '../../../onboarding/data/profile_repository.dart';
import '../../../onboarding/presentation/controllers/registration_cubit.dart';
import '../../../identity_tag/data/identity_card_repository.dart';
import '../../data/payments_repository.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool _biometricsEnabled = true;
  bool _notificationsEnabled = true;
  bool _liveLocationEnabled = true;
  String _language = 'English';
  String? _avatarPath;
  bool _isSaving = false;
  bool _isStartingPayment = false;

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<RegistrationCubit>().state;
    _fullNameCtrl.text =
        state.fullName.isNotEmpty ? state.fullName : 'James Mensah';
    _phoneCtrl.text =
        state.phoneNumber.isNotEmpty ? state.phoneNumber : '+233 24 123 4567';
    _dobCtrl.text = state.dob.isNotEmpty ? state.dob : '12 / 04 / 1990';
    _genderCtrl.text = state.gender.isNotEmpty ? state.gender : 'Male';
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final db = LocalDbService();
    final liveLoc = await db.read('live_location_enabled');
    final biometrics = await db.read('biometrics_enabled');
    final notifications = await db.read('notifications_enabled');
    final language = await db.read('app_language');
    final avatarPath = await db.read('profile_avatar_path');
    if (!mounted) return;
    setState(() {
      _liveLocationEnabled = liveLoc != 'false';
      _biometricsEnabled = biometrics != 'false';
      _notificationsEnabled = notifications != 'false';
      _language = language ?? 'English';
      _avatarPath = avatarPath;
    });
  }

  Future<void> _toggleLiveLocation(bool value) async {
    if (!value) {
      setState(() => _liveLocationEnabled = false);
      await LocalDbService().write('live_location_enabled', 'false');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission was not granted.')),
        );
      }
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    await LocalDbService().write('last_latitude', '${position.latitude}');
    await LocalDbService().write('last_longitude', '${position.longitude}');
    await LocalDbService().write('live_location_enabled', 'true');
    if (mounted) setState(() => _liveLocationEnabled = true);
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _genderCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final cubit = context.read<RegistrationCubit>();
    final updatedState = cubit.state.copyWith(
      fullName: _fullNameCtrl.text,
      phoneNumber: _phoneCtrl.text,
      dob: _dobCtrl.text,
      gender: _genderCtrl.text,
    );
    cubit.updateProfile(updatedState);

    try {
      await ProfileRepository().update({
        'fullName': _fullNameCtrl.text,
        'phoneNumber': _phoneCtrl.text,
        'dateOfBirth': _dobCtrl.text,
        'gender': _genderCtrl.text,
      });
    } catch (_) {
      // If offline, the Cubit still holds the updated state in memory
    }

    setState(() {
      _isEditing = false;
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final auth = LocalAuthentication();
      final supported =
          await auth.isDeviceSupported() && await auth.canCheckBiometrics;
      if (!supported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Biometric authentication is unavailable.')),
          );
        }
        return;
      }
      final authenticated = await auth.authenticate(
        localizedReason: 'Enable biometric login for StockAlert',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!authenticated) return;
    }
    setState(() => _biometricsEnabled = value);
    await LocalDbService().write('biometrics_enabled', value.toString());
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      await ApiClient.instance.patch(
        '/api/v1/notifications',
        body: {'pushEnabled': value},
      );
      await LocalDbService().write('notifications_enabled', value.toString());
      if (mounted) setState(() => _notificationsEnabled = value);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (image == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      var extension = image.path.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        extension = 'jpg';
      }
      final bytes = await image.readAsBytes();
      await ApiClient.instance.post('/api/v1/profile/avatar', body: {
        'contentBase64': base64Encode(bytes),
        'extension': extension,
      });
      await LocalDbService().write('profile_avatar_path', image.path);
      if (mounted) setState(() => _avatarPath = image.path);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _chooseLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<String>(
          groupValue: _language,
          onChanged: (value) => Navigator.pop(context, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['English', 'Twi', 'French']
                .map(
                  (language) => RadioListTile<String>(
                    value: language,
                    title: Text(language),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (selected == null) return;
    await LocalDbService().write('app_language', selected);
    if (mounted) {
      setState(() => _language = selected);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language preference changed to $selected.')),
      );
    }
  }

  Future<void> _openSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@stockalert.app',
      queryParameters: {'subject': 'StockAlert support request'},
    );
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email support@stockalert.app')),
        );
      }
    }
  }

  Future<String?> _askForValue(String title, String initialValue) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  // ignore: unused_element
  Future<void> _openSafety(RegistrationState state) async {
    var name = await LocalDbService().read('trusted_contact_name') ??
        state.emergencyContactName;
    var phone = await LocalDbService().read('trusted_contact_phone') ??
        state.emergencyContactPhone;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safety & trusted contacts', style: AppTextStyles.heading),
                const SizedBox(height: 8),
                Text(
                  'Your registration emergency contact is used first. You can update the trusted contact here.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                      child: Icon(Icons.health_and_safety_outlined)),
                  title: Text(name.isEmpty ? 'No trusted contact' : name),
                  subtitle: Text(phone.isEmpty ? 'Add a phone number' : phone),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () async {
                    final newName =
                        await _askForValue('Trusted contact name', name);
                    if (newName == null || !mounted) return;
                    final newPhone =
                        await _askForValue('Trusted contact phone', phone);
                    if (newPhone == null) return;
                    await LocalDbService()
                        .write('trusted_contact_name', newName);
                    await LocalDbService()
                        .write('trusted_contact_phone', newPhone);
                    setSheetState(() {
                      name = newName;
                      phone = newPhone;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: phone.isEmpty
                        ? null
                        : () => launchUrl(Uri(scheme: 'tel', path: phone)),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call trusted contact'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _openSavedPlaces() async {
    var home = await LocalDbService().read('saved_place_home') ?? '';
    var work = await LocalDbService().read('saved_place_work') ?? '';
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            Text('Saved places', style: AppTextStyles.heading),
            Text('Save addresses for faster pharmacy searches and directions.',
                style: AppTextStyles.body),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              subtitle: Text(home.isEmpty ? 'Add home address' : home),
              onTap: () async {
                final value = await _askForValue('Home address', home);
                if (value != null) {
                  await LocalDbService().write('saved_place_home', value);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('Work'),
              subtitle: Text(work.isEmpty ? 'Add work address' : work),
              onTap: () async {
                final value = await _askForValue('Work address', work);
                if (value != null) {
                  await LocalDbService().write('saved_place_work', value);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _openPayments() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payments', style: AppTextStyles.heading),
              Text('Paystack will use ${_phoneCtrl.text} for mobile payments.',
                  style: AppTextStyles.body),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_android_outlined),
                title: const Text('Mobile money'),
                subtitle: Text(_phoneCtrl.text),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.credit_card_outlined),
                title: Text('Add card securely'),
                subtitle: Text(
                    'Card details are entered only in Paystack checkout and are never stored by StockAlert.'),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                      'Checkout becomes available when the server-side Paystack key and verification webhook are configured.'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isStartingPayment
                      ? null
                      : () async {
                          setState(() => _isStartingPayment = true);
                          try {
                            final payments = PaymentsRepository();
                            final checkout = await payments.startCheckout(
                              amountMinor: 100,
                            );
                            await payments
                                .openCheckout(checkout.authorizationUrl);
                          } catch (error) {
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isStartingPayment = false);
                            }
                          }
                        },
                  icon: _isStartingPayment
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_outline),
                  label: Text(_isStartingPayment
                      ? 'Opening secure checkout…'
                      : 'Make GHS 1.00 test payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _openTransactions() async {
    final raw = await LocalDbService().read('transaction_history');
    final transactions =
        raw == null ? <dynamic>[] : (jsonDecode(raw) as List<dynamic>);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaction history', style: AppTextStyles.heading),
              const SizedBox(height: 16),
              if (transactions.isEmpty)
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.receipt_long_outlined),
                  title: Text('No transactions yet'),
                  subtitle: Text(
                      'Completed pharmacy and consultation payments will appear here.'),
                )
              else
                ...transactions.map((item) => ListTile(title: Text('$item'))),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _openDetailedSupport() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Help & Support', style: AppTextStyles.heading),
              Text(
                  'Get help with accounts, medicine searches, bookings, payments, privacy, or pharmacy orders.',
                  style: AppTextStyles.body),
              const SizedBox(height: 12),
              const ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('Support hours'),
                  subtitle: Text('Monday–Saturday, 8:00 AM–6:00 PM')),
              const ListTile(
                  leading: Icon(Icons.shield_outlined),
                  title: Text('Emergency notice'),
                  subtitle: Text(
                      'StockAlert is not an emergency service. Contact local emergency services for urgent help.')),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openSupport,
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Email support'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _openIdentityPrivacy() async {
    final repository = IdentityCardRepository();
    try {
      var settings = await repository.getMine();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> update({
              bool? sharing,
              bool? name,
              bool? dob,
              bool? emergency,
              bool rotate = false,
            }) async {
              settings = await repository.updatePrivacy(
                sharingEnabled: sharing,
                shareFullName: name,
                shareDateOfBirth: dob,
                shareEmergencyContact: emergency,
                rotateToken: rotate,
              );
              setSheetState(() {});
            }

            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Digital identity privacy',
                      style: AppTextStyles.heading),
                  Text(
                    'The QR contains only a random, replaceable token. Personal details stay on the server and are revealed only to an authenticated pharmacy or consultation provider according to these choices.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Allow identity verification'),
                    subtitle: const Text(
                        'Turning this off makes the QR private immediately.'),
                    value: settings.sharingEnabled,
                    onChanged: (value) => update(sharing: value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Share full name'),
                    value: settings.shareFullName,
                    onChanged: settings.sharingEnabled
                        ? (value) => update(name: value)
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Share date of birth'),
                    value: settings.shareDateOfBirth,
                    onChanged: settings.sharingEnabled
                        ? (value) => update(dob: value)
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Share emergency contact'),
                    subtitle: const Text('Off by default'),
                    value: settings.shareEmergencyContact,
                    onChanged: settings.sharingEnabled
                        ? (value) => update(emergency: value)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => update(rotate: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Replace QR security token'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Log Out'),
          content:
              const Text('Are you sure you want to log out of StockAlert?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // close dialog
                final registrationCubit =
                    this.context.read<RegistrationCubit>();

                try {
                  await Supabase.instance.client.auth.signOut();
                } catch (_) {
                  // The local session is cleared before remote revocation.
                }
                if (!mounted) return;
                registrationCubit.reset();
                this.context.go('/login?switching=true');
              },
              child: const Text('Log Out',
                  style: TextStyle(
                      color: AppColors.statusBad, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationCubit, RegistrationState>(
      builder: (context, state) {
        final email =
            state.email.isNotEmpty ? state.email : 'james.mensah@gmail.com';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/patient/home');
                }
              },
            ),
            title: Text('My Profile', style: AppTextStyles.subheading),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.check : Icons.edit,
                    color: AppColors.accent),
                onPressed: () {
                  if (_isEditing) {
                    _saveProfile();
                  } else {
                    setState(() {
                      _isEditing = true;
                    });
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.hairline),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickAvatar,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      AppColors.accent.withValues(alpha: 0.1),
                                  backgroundImage: _avatarPath == null
                                      ? null
                                      : FileImage(File(_avatarPath!)),
                                  radius: 34,
                                  child: _avatarPath == null
                                      ? const Icon(Icons.person,
                                          color: AppColors.accent, size: 30)
                                      : null,
                                ),
                                const Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.accent,
                                    child: Icon(Icons.camera_alt,
                                        size: 13, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!_isEditing) ...[
                                  Text(_fullNameCtrl.text,
                                      style: AppTextStyles.subheading),
                                  Text(email, style: AppTextStyles.body),
                                  Text(_phoneCtrl.text,
                                      style: AppTextStyles.body),
                                ] else
                                  Text('Edit Mode',
                                      style: AppTextStyles.subheading
                                          .copyWith(color: AppColors.accent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_isEditing) ...[
                        const Divider(height: 24, color: AppColors.hairline),
                        _buildEditableField('Full Name', _fullNameCtrl),
                        _buildEditableField('Phone Number', _phoneCtrl),
                        _buildEditableField('Date of Birth', _dobCtrl),
                        _buildEditableField('Gender', _genderCtrl),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            child: Text(_isSaving ? 'Saving…' : 'Save Changes'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Security & Biometrics', style: AppTextStyles.label),
                const SizedBox(height: 8),
                _buildSwitchTile(
                  icon: Icons.fingerprint,
                  title: 'Face ID / Biometric Login',
                  subtitle: 'Use biometric authentication for faster login',
                  value: _biometricsEnabled,
                  onChanged: _toggleBiometrics,
                ),
                const SizedBox(height: 12),
                _buildNavigationTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () => context.push('/patient/change-password'),
                ),
                const SizedBox(height: 12),
                _buildNavigationTile(
                  icon: Icons.security_outlined,
                  title: 'Sign in & Security',
                  onTap: () => context.push('/patient/security'),
                ),
                const SizedBox(height: 24),

                Text('Safety, places & payments', style: AppTextStyles.label),
                const SizedBox(height: 8),
                _buildNavigationTile(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Safety & trusted contacts',
                  onTap: () => context.push('/patient/safety'),
                ),
                const SizedBox(height: 12),
                _buildNavigationTile(
                  icon: Icons.qr_code_2_outlined,
                  title: 'Digital identity privacy',
                  onTap: () => context.push('/patient/identity-privacy'),
                ),
                const SizedBox(height: 12),
                _buildNavigationTile(
                  icon: Icons.place_outlined,
                  title: 'Saved places',
                  onTap: () => context.push('/patient/saved-places'),
                ),
                const SizedBox(height: 12),
                _buildNavigationTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Payment options',
                  onTap: () => context.push(
                    '/patient/payments',
                    extra: _phoneCtrl.text,
                  ),
                ),
                const SizedBox(height: 12),
                _buildNavigationTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Transaction history',
                  onTap: () => context.push('/patient/transactions'),
                ),
                const SizedBox(height: 24),

                Text('Preferences', style: AppTextStyles.label),
                const SizedBox(height: 8),
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Push Notifications',
                  subtitle:
                      'Remind me of doctor bookings and medication refills',
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
                const SizedBox(height: 12),
                _buildSwitchTile(
                  icon: Icons.my_location_outlined,
                  title: 'Live Location GPS',
                  subtitle:
                      'Use active GPS location to search nearby pharmacies',
                  value: _liveLocationEnabled,
                  onChanged: _toggleLiveLocation,
                ),
                const SizedBox(height: 12),

                _buildNavigationTile(
                  icon: Icons.language,
                  title: 'Language',
                  trailingText: _language,
                  onTap: _chooseLanguage,
                ),
                const SizedBox(height: 12),

                _buildNavigationTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () => context.push('/patient/support'),
                ),
                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _confirmLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusBad,
                      side: const BorderSide(color: AppColors.statusBad),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Log Out'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.hairline),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: controller,
              style: AppTextStyles.subheading.copyWith(fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.subheading),
                Text(subtitle,
                    style: AppTextStyles.body.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: AppTextStyles.subheading),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

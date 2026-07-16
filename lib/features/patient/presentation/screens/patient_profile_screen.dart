import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_db_service.dart';
import '../../../onboarding/presentation/controllers/registration_cubit.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool _biometricsEnabled = true;
  bool _notificationsEnabled = true;
  bool _liveLocationEnabled = true;

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<RegistrationCubit>().state;
    _fullNameCtrl.text = state.fullName.isNotEmpty ? state.fullName : 'James Mensah';
    _phoneCtrl.text = state.phoneNumber.isNotEmpty ? state.phoneNumber : '+233 24 123 4567';
    _dobCtrl.text = state.dob.isNotEmpty ? state.dob : '12 / 04 / 1990';
    _genderCtrl.text = state.gender.isNotEmpty ? state.gender : 'Male';
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final db = LocalDbService();
    final liveLoc = await db.read('live_location_enabled');
    final biometrics = await db.read('biometrics_enabled');
    final notifications = await db.read('notifications_enabled');
    setState(() {
      _liveLocationEnabled = liveLoc != 'false';
      _biometricsEnabled = biometrics != 'false';
      _notificationsEnabled = notifications != 'false';
    });
  }

  Future<void> _toggleLiveLocation(bool value) async {
    setState(() => _liveLocationEnabled = value);
    await LocalDbService().write('live_location_enabled', value.toString());
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
    final cubit = context.read<RegistrationCubit>();
    final updatedState = cubit.state.copyWith(
      fullName: _fullNameCtrl.text,
      phoneNumber: _phoneCtrl.text,
      dob: _dobCtrl.text,
      gender: _genderCtrl.text,
    );
    cubit.updateProfile(updatedState);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': userId,
          'full_name': _fullNameCtrl.text,
          'phone_number': _phoneCtrl.text,
          'dob': _dobCtrl.text,
          'gender': _genderCtrl.text,
        });
      }
    } catch (_) {
      // If offline, the Cubit still holds the updated state in memory
    }

    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    setState(() => _biometricsEnabled = value);
    await LocalDbService().write('biometrics_enabled', value.toString());
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await LocalDbService().write('notifications_enabled', value.toString());
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Log Out'),
          content: const Text('Are you sure you want to log out of StockAlert?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // close dialog

                await Supabase.instance.client.auth.signOut();

                if (mounted) {
                  context.read<RegistrationCubit>().reset();
                  context.go('/');
                }
              },
              child: const Text('Log Out', style: TextStyle(color: AppColors.statusBad, fontWeight: FontWeight.bold)),
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
        final email = state.email.isNotEmpty ? state.email : 'james.mensah@gmail.com';

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
                icon: Icon(_isEditing ? Icons.check : Icons.edit, color: AppColors.accent),
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
                          CircleAvatar(
                            backgroundColor: AppColors.accent.withOpacity(0.1),
                            radius: 28,
                            child: const Icon(Icons.person, color: AppColors.accent, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!_isEditing) ...[
                                  Text(_fullNameCtrl.text, style: AppTextStyles.subheading),
                                  Text(email, style: AppTextStyles.body),
                                  Text(_phoneCtrl.text, style: AppTextStyles.body),
                                ] else
                                  Text('Edit Mode', style: AppTextStyles.subheading.copyWith(color: AppColors.accent)),
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
                            onPressed: _saveProfile,
                            child: const Text('Save Changes'),
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
                const SizedBox(height: 24),

                Text('Preferences', style: AppTextStyles.label),
                const SizedBox(height: 8),
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Remind me of doctor bookings and medication refills',
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
                const SizedBox(height: 12),
                _buildSwitchTile(
                  icon: Icons.my_location_outlined,
                  title: 'Live Location GPS',
                  subtitle: 'Use active GPS location to search nearby pharmacies',
                  value: _liveLocationEnabled,
                  onChanged: _toggleLiveLocation,
                ),
                const SizedBox(height: 12),

                _buildNavigationTile(
                  icon: Icons.language,
                  title: 'Language',
                  trailingText: 'English',
                  onTap: () {},
                ),
                const SizedBox(height: 12),

                _buildNavigationTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
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
                Text(subtitle, style: AppTextStyles.body.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
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
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

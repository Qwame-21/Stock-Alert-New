import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/presentation/controllers/registration_cubit.dart';

class PharmacyMoreScreen extends StatefulWidget {
  const PharmacyMoreScreen({super.key});

  @override
  State<PharmacyMoreScreen> createState() => _PharmacyMoreScreenState();
}

class _PharmacyMoreScreenState extends State<PharmacyMoreScreen> {
  bool _alertOnLowStock = true;
  bool _alertOnExpiry = true;

  final _pharmacyNameCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _authorityCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<RegistrationCubit>().state;
    _pharmacyNameCtrl.text = state.pharmacyName.isNotEmpty ? state.pharmacyName : 'Green Pharmacy';
    _licenseCtrl.text = state.licenseNumber.isNotEmpty ? state.licenseNumber : 'PHA-90210-X';
    _locationCtrl.text = state.location.isNotEmpty ? state.location : 'Spintex Road, Accra';
    _authorityCtrl.text = state.registrationAuthority.isNotEmpty ? state.registrationAuthority : 'Pharmacy Council of Ghana';
    _hoursCtrl.text = state.operatingHours.isNotEmpty ? state.operatingHours : '8:00 AM - 9:00 PM';
    _supplierCtrl.text = state.supplierPreference.isNotEmpty ? state.supplierPreference : 'Standard Wholesales Ltd';
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // Alert preferences will be stored in Supabase profile in a future pass.
    // Defaults retained for now.
  }

  @override
  void dispose() {
    _pharmacyNameCtrl.dispose();
    _licenseCtrl.dispose();
    _locationCtrl.dispose();
    _authorityCtrl.dispose();
    _hoursCtrl.dispose();
    _supplierCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final cubit = context.read<RegistrationCubit>();
    final updatedState = cubit.state.copyWith(
      pharmacyName: _pharmacyNameCtrl.text,
      licenseNumber: _licenseCtrl.text,
      location: _locationCtrl.text,
      registrationAuthority: _authorityCtrl.text,
      operatingHours: _hoursCtrl.text,
      supplierPreference: _supplierCtrl.text,
    );
    cubit.updateProfile(updatedState);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': userId,
          'pharmacy_name': _pharmacyNameCtrl.text,
          'license_number': _licenseCtrl.text,
          'location': _locationCtrl.text,
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
        const SnackBar(content: Text('Pharmacy details saved successfully')),
      );
    }
  }

  Future<void> _toggleLowStock(bool value) async {
    setState(() => _alertOnLowStock = value);
    // Alert preference persistence via Supabase coming in a future pass
  }

  Future<void> _toggleExpiry(bool value) async {
    setState(() => _alertOnExpiry = value);
    // Alert preference persistence via Supabase coming in a future pass
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

  void _showStaffDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Staff Accounts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ListTile(
                leading: CircleAvatar(child: Text('EA')),
                title: Text('Emmanuel Ampadu'),
                subtitle: Text('Admin / Pharmacist'),
              ),
              ListTile(
                leading: CircleAvatar(child: Text('SM')),
                title: Text('Sarah Mensah'),
                subtitle: Text('Dispenser'),
              ),
              ListTile(
                leading: CircleAvatar(child: Text('KO')),
                title: Text('Kenneth Osei'),
                subtitle: Text('Dispenser (Temporary)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        );
      },
    );
  }

  void _showSupplierDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Supplier Preferences'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Primary Supplier:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_supplierCtrl.text, style: AppTextStyles.subheading),
              const SizedBox(height: 16),
              const Text('Available Distributors:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('• Standard Wholesales Ltd\n• Kinapharma Distributor Accra\n• Tobinco Pharmaceuticals'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.accent)),
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
                  context.go('/pharmacy/dashboard');
                }
              },
            ),
            title: Text('Settings & More', style: AppTextStyles.subheading),
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
                // Pharmacy Details Card
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
                            child: const Icon(Icons.storefront, color: AppColors.accent, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!_isEditing) ...[
                                  Text(_pharmacyNameCtrl.text, style: AppTextStyles.subheading),
                                  Text('License: ${_licenseCtrl.text}', style: AppTextStyles.body),
                                  Text(_locationCtrl.text, style: AppTextStyles.body),
                                ] else
                                  Text('Edit Mode', style: AppTextStyles.subheading.copyWith(color: AppColors.accent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_isEditing) ...[
                        const Divider(height: 24, color: AppColors.hairline),
                        _buildEditableField('Pharmacy Name', _pharmacyNameCtrl),
                        _buildEditableField('License Number', _licenseCtrl),
                        _buildEditableField('Registration Authority', _authorityCtrl),
                        _buildEditableField('Location', _locationCtrl),
                        _buildEditableField('Operating Hours', _hoursCtrl),
                        _buildEditableField('Primary Supplier', _supplierCtrl),
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

                Text('Alert Preferences', style: AppTextStyles.label),
                const SizedBox(height: 8),
                _buildSwitchTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Low Stock Alerts',
                  subtitle: 'Notify when a medicine count falls below threshold',
                  value: _alertOnLowStock,
                  onChanged: _toggleLowStock,
                ),
                const SizedBox(height: 12),
                _buildSwitchTile(
                  icon: Icons.warning_amber_outlined,
                  title: 'Expiry Warnings',
                  subtitle: 'Notify when batch is within 30 days of expiry',
                  value: _alertOnExpiry,
                  onChanged: _toggleExpiry,
                ),
                const SizedBox(height: 24),

                Text('Pharmacy Management', style: AppTextStyles.label),
                const SizedBox(height: 8),
                _buildNavigationTile(
                  icon: Icons.people_outline,
                  title: 'Staff Accounts',
                  trailingText: '3 Active',
                  onTap: _showStaffDialog,
                ),
                const SizedBox(height: 12),
                _buildNavigationTile(
                  icon: Icons.local_shipping_outlined,
                  title: 'Supplier Preferences',
                  onTap: _showSupplierDialog,
                ),
                const SizedBox(height: 12),
                _buildNavigationTile(
                  icon: Icons.help_outline,
                  title: 'Support & Helpdesk',
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

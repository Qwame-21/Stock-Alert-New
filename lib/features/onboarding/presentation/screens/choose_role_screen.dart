import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/registration_cubit.dart';

class ChooseRoleScreen extends StatefulWidget {
  final bool loginMode;
  const ChooseRoleScreen({super.key, this.loginMode = false});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    void goBack() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go(widget.loginMode ? '/login' : '/');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: goBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(widget.loginMode ? 'Log in as…' : 'I am…',
                      style: AppTextStyles.heading),
                  const SizedBox(height: 6),
                  Text(
                    widget.loginMode
                        ? 'Choose the workspace connected to your account.'
                        : 'Choose your account type to personalize StockAlert.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 24),
                  _RoleTile(
                    icon: Icons.person_outline,
                    label: 'Patient',
                    selected: _selected == 'patient',
                    onTap: () => setState(() => _selected = 'patient'),
                  ),
                  const SizedBox(height: 12),
                  _RoleTile(
                    icon: Icons.medical_services_outlined,
                    label: 'Consultation Provider',
                    selected: _selected == 'provider',
                    onTap: () => setState(() => _selected = 'provider'),
                  ),
                  const SizedBox(height: 12),
                  _RoleTile(
                    icon: Icons.storefront_outlined,
                    label: 'Community Pharmacy',
                    selected: _selected == 'pharmacy',
                    onTap: () => setState(() => _selected = 'pharmacy'),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selected == null
                          ? null
                          : () {
                              if (widget.loginMode) {
                                context.go('/login?role=$_selected');
                                return;
                              }
                              if (_selected == 'provider') {
                                context.push('/register/provider');
                              } else {
                                context
                                    .read<RegistrationCubit>()
                                    .setRole(_selected!);
                                context.push('/register/1');
                              }
                            },
                      child: Text(widget.loginMode
                          ? 'Continue to login'
                          : 'Create account'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(widget.loginMode
                          ? '/choose-role'
                          : '/choose-role?mode=login'),
                      child: Text(widget.loginMode
                          ? 'No account? Create one'
                          : 'Already have an account? Log in'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              )),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: AppTextStyles.subheading),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

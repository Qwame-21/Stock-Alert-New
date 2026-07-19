import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/onboarding/presentation/controllers/registration_cubit.dart';
import '../theme/app_theme.dart';

class AccountMenuButton extends StatelessWidget {
  final String roleLabel;
  final String profileRoute;
  final bool openDirectly;

  const AccountMenuButton({
    super.key,
    required this.roleLabel,
    required this.profileRoute,
    this.openDirectly = false,
  });

  Future<void> _switchAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Switch account?'),
        content: Text(
          'You are signed in as a $roleLabel account. StockAlert opens the '
          'workspace assigned to each registered account.\n\nSigning out lets '
          'you use a different patient, pharmacy, or provider account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay signed in'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final registration = context.read<RegistrationCubit>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Supabase clears the local session before remote revocation.
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    registration.reset();
    context.go('/login?switching=true');
  }

  @override
  Widget build(BuildContext context) {
    if (openDirectly) {
      return IconButton(
        tooltip: 'Open $roleLabel account',
        onPressed: () => context.push(profileRoute),
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.hairline)),
          child: const Icon(Icons.account_circle_outlined,
              color: AppColors.accent, size: 22),
        ),
      );
    }
    return PopupMenuButton<String>(
      tooltip: 'Account options',
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline),
        ),
        child: const Icon(Icons.account_circle_outlined,
            color: AppColors.textSecondary, size: 22),
      ),
      onSelected: (value) {
        if (value == 'profile') context.push(profileRoute);
        if (value == 'switch') _switchAccount(context);
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text('$roleLabel account', style: AppTextStyles.label),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'profile',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.manage_accounts_outlined),
            title: Text('Profile and settings'),
          ),
        ),
        const PopupMenuItem(
          value: 'switch',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading:
                Icon(Icons.switch_account_outlined, color: AppColors.statusBad),
            title: Text('Switch account / Sign out'),
          ),
        ),
      ],
    );
  }
}

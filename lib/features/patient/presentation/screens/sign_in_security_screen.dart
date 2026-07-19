import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_db_service.dart';
import '../../../../core/theme/app_theme.dart';

class SignInSecurityScreen extends StatefulWidget {
  const SignInSecurityScreen({super.key});
  @override
  State<SignInSecurityScreen> createState() => _SignInSecurityScreenState();
}

class _SignInSecurityScreenState extends State<SignInSecurityScreen> {
  bool _passkey = false, _twoStep = false, _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = LocalDbService();
    final p = await db.read('passkey_enabled');
    final t = await db.read('two_step_enabled');
    if (mounted) {
      setState(() {
        _passkey = p == 'true';
        _twoStep = t == 'true';
      });
    }
  }

  Future<void> _setPasskey(bool value) async {
    if (value) {
      final auth = LocalAuthentication();
      if (!await auth.isDeviceSupported() ||
          !await auth.authenticate(
              localizedReason: 'Verify your identity to set up device sign-in')) {
        return;
      }
    }
    await LocalDbService().write('passkey_enabled', '$value');
    if (mounted) setState(() => _passkey = value);
  }

  Future<void> _setTwoStep(bool value) async {
    await LocalDbService().write('two_step_enabled', '$value');
    if (mounted) {
      setState(() => _twoStep = value);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value
              ? 'Two-step verification will be required on this device.'
              : 'Two-step verification turned off.')));
    }
  }

  Future<void> _oauth(OAuthProvider provider) =>
      Supabase.instance.client.auth.signInWithOAuth(provider,
          redirectTo:
              kIsWeb ? null : 'io.supabase.stockalert://login-callback/');
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
                    title: const Text('Delete account permanently?'),
                    content: const Text(
                        'Your profile and access will be permanently removed. This cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.statusBad),
                          child: const Text('Delete account'))
                    ])) ??
        false;
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await ApiClient.instance.delete('/api/v1/account');
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Sign in & security')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Protect your account', style: AppTextStyles.heading),
        Text(
            'Choose how you sign in and add extra checks to keep your health information private.',
            style: AppTextStyles.body),
        const SizedBox(height: 18),
        SwitchListTile(
            value: _passkey,
            onChanged: _busy ? null : _setPasskey,
            title: const Text('Device passkey'),
            subtitle: const Text(
                'Use Face ID, fingerprint or your device screen lock instead of repeatedly entering a password.')),
        SwitchListTile(
            value: _twoStep,
            onChanged: _busy ? null : _setTwoStep,
            title: const Text('Two-step verification'),
            subtitle: const Text(
                'Require an additional verification check when signing in on this device.')),
        const SizedBox(height: 16),
        Text('Other login options', style: AppTextStyles.subheading),
        if (kIsWeb || !Platform.isIOS)
          ListTile(
              leading: const Icon(Icons.g_mobiledata, size: 34),
              title: const Text('Continue with Google'),
              subtitle: const Text(
                  'Connect your Google account as another sign-in option.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _oauth(OAuthProvider.google)),
        if (!kIsWeb && (Platform.isIOS || Platform.isMacOS))
          ListTile(
              leading: const Icon(Icons.apple, size: 30),
              title: const Text('Continue with Apple'),
              subtitle:
                  const Text('Use the Apple ID connected to this device.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _oauth(OAuthProvider.apple)),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 12),
        Text('Account deletion',
            style:
                AppTextStyles.subheading.copyWith(color: AppColors.statusBad)),
        Text(
            'Deleting your account permanently removes your StockAlert access.',
            style: AppTextStyles.body),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: _busy ? null : _delete,
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(_busy ? 'Deleting…' : 'Delete account'),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusBad,
                side: const BorderSide(color: AppColors.statusBad)))
      ]));
}

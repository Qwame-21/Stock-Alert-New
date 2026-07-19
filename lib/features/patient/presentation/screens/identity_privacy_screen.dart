import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../identity_tag/data/identity_card_repository.dart';

class IdentityPrivacyScreen extends StatefulWidget {
  const IdentityPrivacyScreen({super.key});
  @override
  State<IdentityPrivacyScreen> createState() => _IdentityPrivacyScreenState();
}

class _IdentityPrivacyScreenState extends State<IdentityPrivacyScreen> {
  final _repo = IdentityCardRepository();
  dynamic _settings;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await _repo.getMine();
      if (mounted) setState(() => _settings = value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _update(
      {bool? sharing,
      bool? name,
      bool? dob,
      bool? emergency,
      bool rotate = false}) async {
    setState(() => _busy = true);
    try {
      final value = await _repo.updatePrivacy(
          sharingEnabled: sharing,
          shareFullName: name,
          shareDateOfBirth: dob,
          shareEmergencyContact: emergency,
          rotateToken: rotate);
      if (mounted) setState(() => _settings = value);
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
        appBar: AppBar(title: const Text('Digital identity privacy')),
        body: _settings == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(20), children: [
                Text('Control what you share', style: AppTextStyles.heading),
                Text(
                    'Your QR contains a replaceable security token. Only authenticated pharmacies and providers can see the details you allow.',
                    style: AppTextStyles.body),
                const SizedBox(height: 18),
                SwitchListTile(
                    title: const Text('Allow identity verification'),
                    subtitle: const Text(
                        'Turn this off to make your QR private immediately.'),
                    value: _settings.sharingEnabled,
                    onChanged: _busy ? null : (v) => _update(sharing: v)),
                SwitchListTile(
                    title: const Text('Share full name'),
                    subtitle:
                        const Text('Shows your registered name to a verifier.'),
                    value: _settings.shareFullName,
                    onChanged: _busy || !_settings.sharingEnabled
                        ? null
                        : (v) => _update(name: v)),
                SwitchListTile(
                    title: const Text('Share date of birth'),
                    subtitle: const Text(
                        'Useful when a provider needs to match your record.'),
                    value: _settings.shareDateOfBirth,
                    onChanged: _busy || !_settings.sharingEnabled
                        ? null
                        : (v) => _update(dob: v)),
                SwitchListTile(
                    title: const Text('Share emergency contact'),
                    subtitle: const Text(
                        'Off by default. Enable only when you are comfortable.'),
                    value: _settings.shareEmergencyContact,
                    onChanged: _busy || !_settings.sharingEnabled
                        ? null
                        : (v) => _update(emergency: v)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                    onPressed: _busy ? null : () => _update(rotate: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Replace QR security token')),
              ]),
      );
}

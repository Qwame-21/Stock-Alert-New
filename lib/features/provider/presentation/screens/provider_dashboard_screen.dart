import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_db_service.dart';
import '../../../onboarding/presentation/controllers/registration_cubit.dart';
import '../../data/provider_repository.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final _repository = ProviderRepository();
  final Map<int, bool> _days = {
    for (var day = 1; day <= 7; day++) day: day <= 5
  };
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  int _duration = 30;
  bool _accepting = true;
  bool _loading = true;
  Map<String, dynamic>? _profile;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await _repository.getMe();
      final avatar = await LocalDbService().read('provider_avatar_path');
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _avatarPath = avatar;
        _accepting = profile['is_accepting_bookings'] as bool? ?? true;
        _duration = (profile['consultation_duration'] as num?)?.toInt() ?? 30;
        _days.updateAll((_, __) => false);
        for (final item
            in profile['provider_availability'] as List? ?? const []) {
          _days[(item as Map)['weekday'] as int] = true;
        }
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _updatePhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (image == null) return;
    var extension = image.path.split('.').last.toLowerCase();
    if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) extension = 'jpg';
    setState(() => _loading = true);
    try {
      await ApiClient.instance.post('/api/v1/profile/avatar', body: {
        'contentBase64': base64Encode(await image.readAsBytes()),
        'extension': extension,
      });
      await LocalDbService().write('provider_avatar_path', image.path);
      if (mounted) setState(() => _avatarPath = image.path);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _time(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await _repository.saveAvailability(
        accepting: _accepting,
        duration: _duration,
        availability: [
          for (final entry in _days.entries)
            if (entry.value)
              {
                'weekday': entry.key,
                'startTime': _time(_start),
                'endTime': _time(_end),
              },
        ],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability published successfully.')),
        );
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

  @override
  Widget build(BuildContext context) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider workspace'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (_) {
                // The local session is cleared before remote revocation.
              }
              if (context.mounted) {
                context.read<RegistrationCubit>().reset();
                context.go('/login?switching=true');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading && _profile == null
          ? const SkeletonDashboard()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(children: [
                  InkWell(
                    onTap: _loading ? null : _updatePhoto,
                    borderRadius: BorderRadius.circular(40),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.accent.withValues(alpha: .1),
                      backgroundImage: _avatarPath == null
                          ? null
                          : FileImage(File(_avatarPath!)),
                      child: _avatarPath == null
                          ? const Icon(Icons.add_a_photo_outlined,
                              color: AppColors.accent)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_profile?['display_name'] as String? ?? 'Provider',
                            style: AppTextStyles.heading),
                        Text(_profile?['specialty'] as String? ?? '',
                            style: AppTextStyles.body),
                        TextButton.icon(
                            onPressed: _loading ? null : _updatePhoto,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Update professional photo')),
                      ])),
                ]),
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    'Verification: ${_profile?['verification_status'] ?? 'pending'}',
                  ),
                ),
                const ExpansionTile(
                  title: Text('Provider Code of Conduct'),
                  subtitle: Text('Required standards for every consultation'),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                          'Protect patient privacy, communicate respectfully, work only within verified qualifications, keep appointment information accurate, avoid discrimination, and follow clinical emergency-escalation procedures.'),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  value: _accepting,
                  onChanged: (value) => setState(() => _accepting = value),
                  title: const Text('Accept patient bookings'),
                  subtitle: const Text(
                    'When disabled, your profile and slots are hidden from patients.',
                  ),
                ),
                const SizedBox(height: 16),
                Text('Weekly working days', style: AppTextStyles.subheading),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var index = 0; index < names.length; index++)
                      FilterChip(
                        label: Text(names[index]),
                        selected: _days[index + 1]!,
                        onSelected: (value) =>
                            setState(() => _days[index + 1] = value),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Starts'),
                        subtitle: Text(_start.format(context)),
                        onTap: () async {
                          final value = await showTimePicker(
                              context: context, initialTime: _start);
                          if (value != null) setState(() => _start = value);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('Ends'),
                        subtitle: Text(_end.format(context)),
                        onTap: () async {
                          final value = await showTimePicker(
                              context: context, initialTime: _end);
                          if (value != null) setState(() => _end = value);
                        },
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<int>(
                  initialValue: _duration,
                  decoration:
                      const InputDecoration(labelText: 'Appointment duration'),
                  items: const [15, 20, 30, 45, 60]
                      .map((value) => DropdownMenuItem(
                          value: value, child: Text('$value minutes')))
                      .toList(),
                  onChanged: (value) => setState(() => _duration = value!),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: const Icon(Icons.publish),
                  label: const Text('Publish availability'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/provider/bookings'),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('View patient appointments'),
                ),
              ],
            ),
    );
  }
}

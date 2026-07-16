import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await _repository.getMe();
      if (!mounted) return;
      setState(() {
        _profile = profile;
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
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading && _profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(_profile?['display_name'] as String? ?? 'Provider',
                    style: AppTextStyles.heading),
                Text(_profile?['specialty'] as String? ?? '',
                    style: AppTextStyles.body),
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    'Verification: ${_profile?['verification_status'] ?? 'pending'}',
                  ),
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
                  value: _duration,
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

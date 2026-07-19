import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../core/widgets/top_notice.dart';
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

class _ProviderHero extends StatelessWidget {
  const _ProviderHero({
    required this.name,
    required this.specialty,
    required this.verification,
    required this.image,
    required this.onPhotoTap,
  });

  final String name, specialty, verification;
  final ImageProvider<Object>? image;
  final VoidCallback? onPhotoTap;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(children: [
          InkWell(
            onTap: onPhotoTap,
            borderRadius: BorderRadius.circular(40),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white.withValues(alpha: .16),
              backgroundImage: image,
              child: image == null
                  ? const Icon(Icons.add_a_photo_outlined, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.heading
                        .copyWith(color: Colors.white, fontSize: 21)),
                Text(specialty,
                    style: AppTextStyles.body
                        .copyWith(color: Colors.white.withValues(alpha: .8))),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    verification == 'verified'
                        ? 'Verified provider'
                        : 'Verification: $verification',
                    style: AppTextStyles.label.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Update professional photo',
            onPressed: onPhotoTap,
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
          ),
        ]),
      );
}

class _WorkspaceSection extends StatelessWidget {
  const _WorkspaceSection({
    required this.number,
    required this.title,
    required this.description,
    required this.children,
  });

  final String number, title, description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle),
              child: Text(number,
                  style: AppTextStyles.label.copyWith(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.subheading),
                    Text(description, style: AppTextStyles.body),
                  ]),
            ),
          ]),
          const SizedBox(height: 16),
          ...children,
        ]),
      );
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final _repository = ProviderRepository();
  final Map<int, bool> _days = {
    for (var day = 1; day <= 7; day++) day: day <= 5
  };
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  int _duration = 30;
  String _mode = 'both';
  final _videoFee = TextEditingController(text: '100');
  final _inPersonFee = TextEditingController(text: '150');
  bool _accepting = true;
  bool _loading = true;
  Map<String, dynamic>? _profile;
  String? _avatarPath;
  String? _avatarUrl;

  ImageProvider<Object>? get _avatarImage {
    if (_avatarPath != null) return FileImage(File(_avatarPath!));
    if (_avatarUrl != null) return NetworkImage(_avatarUrl!);
    return null;
  }

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
        _avatarUrl = profile['avatar_url'] as String?;
        _accepting = profile['is_accepting_bookings'] as bool? ?? true;
        _duration = (profile['consultation_duration'] as num?)?.toInt() ?? 30;
        _mode = profile['consultation_mode'] as String? ?? 'video';
        _videoFee.text = '${(profile['video_fee'] as num?)?.toDouble() ?? 100}';
        _inPersonFee.text =
            '${(profile['in_person_fee'] as num?)?.toDouble() ?? 150}';
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

  @override
  void dispose() {
    _videoFee.dispose();
    _inPersonFee.dispose();
    super.dispose();
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
        consultationMode: _mode,
        videoFee: double.tryParse(_videoFee.text) ?? 0,
        inPersonFee: double.tryParse(_inPersonFee.text) ?? 0,
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
        showTopNotice(
          context,
          title: 'Consultation settings published',
          message: 'Patients can now see your modes, prices and availability.',
          type: TopNoticeType.success,
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
                _ProviderHero(
                  name: _profile?['display_name'] as String? ?? 'Provider',
                  specialty: _profile?['specialty'] as String? ?? '',
                  verification:
                      _profile?['verification_status'] as String? ?? 'pending',
                  image: _avatarImage,
                  onPhotoTap: _loading ? null : _updatePhoto,
                ),
                const SizedBox(height: 18),
                _WorkspaceSection(
                  number: '01',
                  title: 'Booking visibility',
                  description: 'Control whether patients can discover you.',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _accepting,
                      onChanged: (value) => setState(() => _accepting = value),
                      title: const Text('Accept patient bookings'),
                      subtitle: const Text(
                        'When disabled, your profile and slots are hidden from patients.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _WorkspaceSection(
                  number: '02',
                  title: 'Consultation experience',
                  description:
                      'Choose how you meet patients and set clear fees.',
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _mode,
                      decoration: const InputDecoration(
                          labelText: 'Interaction types offered'),
                      items: const [
                        DropdownMenuItem(
                            value: 'video', child: Text('Video consultation')),
                        DropdownMenuItem(
                            value: 'in_person',
                            child: Text('In-person consultation')),
                        DropdownMenuItem(
                            value: 'both', child: Text('Video and in person')),
                      ],
                      onChanged: (value) => setState(() => _mode = value!),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: TextFormField(
                        controller: _videoFee,
                        enabled: _mode != 'in_person',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Video price (GHS)'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextFormField(
                        controller: _inPersonFee,
                        enabled: _mode != 'video',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'In-person price (GHS)'),
                      )),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                        'Patients pay a 50% deposit. A declined request is eligible for refund.',
                        style: AppTextStyles.body),
                  ],
                ),
                const SizedBox(height: 14),
                _WorkspaceSection(
                  number: '03',
                  title: 'Weekly schedule',
                  description:
                      'Select active days, hours and appointment length.',
                  children: [
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
                      decoration: const InputDecoration(
                          labelText: 'Appointment duration'),
                      items: const [15, 20, 30, 45, 60]
                          .map((value) => DropdownMenuItem(
                              value: value, child: Text('$value minutes')))
                          .toList(),
                      onChanged: (value) => setState(() => _duration = value!),
                    ),
                  ],
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

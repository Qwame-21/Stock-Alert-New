import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../core/widgets/top_notice.dart';
import '../../../provider/data/provider_repository.dart';
import '../../data/models/appointment.dart';
import '../controllers/bookings_cubit.dart';

class BookConsultationScreen extends StatefulWidget {
  const BookConsultationScreen({super.key});

  @override
  State<BookConsultationScreen> createState() => _BookConsultationScreenState();
}

class _BookConsultationScreenState extends State<BookConsultationScreen> {
  final _repository = ProviderRepository();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  List<ConsultationProvider> _providers = const [];
  ConsultationProvider? _provider;
  DateTime? _slot;
  bool _loading = true;
  bool _booking = false;
  String? _error;
  String? _mode;
  final _reason = TextEditingController();
  final _condition = TextEditingController();
  final _support = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reason.dispose();
    _condition.dispose();
    _support.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _provider = null;
      _slot = null;
    });
    try {
      final providers = await _repository.list(_date);
      if (!mounted) return;
      setState(() {
        _providers = providers;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (value != null) {
      _date = value;
      await _load();
    }
  }

  String _time(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    return '$hour:${value.minute.toString().padLeft(2, '0')} '
        '${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _book() async {
    final provider = _provider;
    final slot = _slot;
    if (provider == null || slot == null) return;
    final appointment = Appointment(
      id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      providerId: provider.id,
      doctorName: provider.name,
      specialty: provider.specialty,
      date: '${slot.day}/${slot.month}/${slot.year}',
      time: _time(slot),
      notes:
          '${provider.consultationMode == 'video' ? 'Video' : 'Consultation'} appointment.',
      consultationMode: _mode,
      clinicalReason: _reason.text.trim(),
      patientCondition: _condition.text.trim(),
      requestedSupport: _support.text.trim(),
    );
    setState(() => _booking = true);
    try {
      await context.read<BookingsCubit>().addBooking(appointment);
      if (mounted) {
        showTopNotice(
          context,
          title: 'Appointment requested',
          message:
              '${provider.name} will review your ${_time(slot)} consultation.',
          type: TopNoticeType.success,
        );
        context.go('/patient/bookings');
      }
    } catch (error) {
      if (mounted) {
        showTopNotice(
          context,
          title: 'Could not confirm appointment',
          message: friendlyNoticeMessage(error),
          type: TopNoticeType.error,
          duration: const Duration(seconds: 6),
        );
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  String _dayLabel(DateTime value) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[value.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book a consultation')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [
              Expanded(
                  child: Text('Choose a day', style: AppTextStyles.subheading)),
              TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Full calendar')),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 14,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = DateUtils.dateOnly(
                      DateTime.now().add(Duration(days: index + 1)));
                  final selected = DateUtils.isSameDay(day, _date);
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) async {
                      setState(() => _date = day);
                      await _load();
                    },
                    label: SizedBox(
                        width: 42,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_dayLabel(day)),
                          Text('${day.day}',
                              style: AppTextStyles.subheading.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textPrimary))
                        ])),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
                'Selected: ${_dayLabel(_date)}, ${_date.day}/${_date.month}/${_date.year}',
                style: AppTextStyles.body.copyWith(color: AppColors.accent)),
            const Divider(),
            Text('Available verified providers',
                style: AppTextStyles.subheading),
            Text(
              'Only providers with published working hours and an available server slot are shown.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 12),
            if (_loading)
              const SkeletonList(itemCount: 5, showHeader: false)
            else if (_error != null)
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text(_error!),
              )
            else if (_providers.isEmpty)
              const _EmptyProviders()
            else
              RadioGroup<ConsultationProvider>(
                groupValue: _provider,
                onChanged: (value) => setState(() {
                  _provider = value;
                  _slot = null;
                  _mode = value?.consultationMode == 'both'
                      ? null
                      : value?.consultationMode;
                }),
                child: Column(
                  children: [
                    for (final provider in _providers)
                      if (provider.slots.isNotEmpty)
                        _ProviderOption(
                          provider: provider,
                          selected: _provider == provider,
                          onSelected: () => setState(() {
                            _provider = provider;
                            _slot = null;
                            _mode = provider.consultationMode == 'both'
                                ? null
                                : provider.consultationMode;
                          }),
                        ),
                  ],
                ),
              ),
            if (_provider != null) ...[
              const SizedBox(height: 20),
              Text('How would you like to meet?',
                  style: AppTextStyles.subheading),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  if (_provider!.consultationMode != 'in_person')
                    ButtonSegment(
                        value: 'video',
                        icon: const Icon(Icons.videocam_outlined),
                        label: Text(
                            'Video • GHS ${_provider!.videoFee.toStringAsFixed(2)}')),
                  if (_provider!.consultationMode != 'video')
                    ButtonSegment(
                        value: 'in_person',
                        icon: const Icon(Icons.meeting_room_outlined),
                        label: Text(
                            'In person • GHS ${_provider!.inPersonFee.toStringAsFixed(2)}')),
                ],
                selected: _mode == null ? {} : {_mode!},
                emptySelectionAllowed: true,
                onSelectionChanged: (value) =>
                    setState(() => _mode = value.firstOrNull),
              ),
              if (_mode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '50% deposit: GHS ${((_mode == 'video' ? _provider!.videoFee : _provider!.inPersonFee) / 2).toStringAsFixed(2)}',
                    style:
                        AppTextStyles.label.copyWith(color: AppColors.accent),
                  ),
                ),
              const SizedBox(height: 18),
              Text('What do you need help with?',
                  style: AppTextStyles.subheading),
              const SizedBox(height: 8),
              TextField(
                  controller: _reason,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      labelText: 'Reason for consultation',
                      hintText: 'e.g. Persistent headache')),
              const SizedBox(height: 10),
              TextField(
                  controller: _condition,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      labelText: 'Condition or symptoms',
                      hintText: 'When it started and how you feel'),
                  maxLines: 2),
              const SizedBox(height: 10),
              TextField(
                  controller: _support,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      labelText: 'What would you like from the provider?',
                      hintText: 'Advice, review, prescription guidance…'),
                  maxLines: 2),
              const SizedBox(height: 20),
              Text('Available times', style: AppTextStyles.subheading),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in _provider!.slots)
                    ChoiceChip(
                      label: Text(_time(slot)),
                      selected: _slot == slot,
                      onSelected: (_) => setState(() => _slot = slot),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _slot == null ||
                        _mode == null ||
                        _reason.text.trim().length < 2 ||
                        _condition.text.trim().length < 2 ||
                        _support.text.trim().length < 2 ||
                        _booking
                    ? null
                    : _book,
                child: Text(_booking
                    ? 'Confirming…'
                    : _slot == null
                        ? 'Select a time'
                        : 'Confirm ${_dayLabel(_slot!)} ${_slot!.day}/${_slot!.month} at ${_time(_slot!)}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProviderOption extends StatefulWidget {
  const _ProviderOption({
    required this.provider,
    required this.selected,
    required this.onSelected,
  });

  final ConsultationProvider provider;
  final bool selected;
  final VoidCallback onSelected;

  @override
  State<_ProviderOption> createState() => _ProviderOptionState();
}

class _ProviderOptionState extends State<_ProviderOption> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.selected
              ? AppColors.accent.withValues(alpha: .08)
              : Colors.white,
          border: Border.all(
            color: widget.selected ? AppColors.accent : AppColors.hairline,
            width: widget.selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(children: [
          InkWell(
            onTap: widget.onSelected,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: AppColors.accent.withValues(alpha: .12),
                  backgroundImage: provider.avatarUrl == null
                      ? null
                      : NetworkImage(provider.avatarUrl!),
                  child: provider.avatarUrl == null
                      ? const Icon(Icons.person_outline,
                          color: AppColors.accent)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.name, style: AppTextStyles.subheading),
                      const SizedBox(height: 2),
                      Text(
                        '${provider.specialty} • ${provider.yearsExperience} years',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${provider.durationMinutes} min • ${provider.consultationMode.replaceAll('_', ' ')}',
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Icon(
                    widget.selected
                        ? Icons.radio_button_checked
                        : Icons.circle_outlined,
                    color: widget.selected
                        ? AppColors.accent
                        : AppColors.textSecondary),
              ]),
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(children: [
                Text('About this provider',
                    style: AppTextStyles.label.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? .5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(Icons.keyboard_arrow_down, size: 22),
                ),
              ]),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              alignment: Alignment.centerLeft,
              child: Text(
                provider.bio ?? 'Verified consultation provider.',
                style: AppTextStyles.body,
                textAlign: TextAlign.left,
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ]),
      ),
    );
  }
}

class _EmptyProviders extends StatelessWidget {
  const _EmptyProviders();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.event_busy, size: 48),
          const SizedBox(height: 12),
          Text(
            'No provider has published an available slot for this date.',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

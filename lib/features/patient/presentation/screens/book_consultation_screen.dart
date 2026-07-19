import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
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
    );
    setState(() => _booking = true);
    try {
      await context.read<BookingsCubit>().addBooking(appointment);
      if (mounted) context.go('/patient/bookings');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
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
                }),
                child: Column(
                  children: [
                    for (final provider in _providers)
                      if (provider.slots.isNotEmpty)
                        Card(
                          child: RadioListTile<ConsultationProvider>(
                            value: provider,
                            title: Text(provider.name),
                            subtitle: Text(
                              '${provider.specialty} · ${provider.yearsExperience} years\n'
                              '${provider.consultationMode.replaceAll('_', ' ')} · '
                              '${provider.durationMinutes} minutes',
                            ),
                            isThreeLine: true,
                          ),
                        ),
                  ],
                ),
              ),
            if (_provider != null) ...[
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
                onPressed: _slot == null || _booking ? null : _book,
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
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
    try {
      await context.read<BookingsCubit>().addBooking(appointment);
      if (mounted) context.go('/patient/bookings');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
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
            Text('Choose a date', style: AppTextStyles.subheading),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text('${_date.day}/${_date.month}/${_date.year}'),
              trailing: const Text('Change'),
              onTap: _pickDate,
            ),
            const Divider(),
            Text('Available verified providers',
                style: AppTextStyles.subheading),
            Text(
              'Only providers with published working hours and an available server slot are shown.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text(_error!),
              )
            else if (_providers.isEmpty)
              const _EmptyProviders()
            else
              for (final provider in _providers)
                if (provider.slots.isNotEmpty)
                  Card(
                    child: RadioListTile<ConsultationProvider>(
                      value: provider,
                      groupValue: _provider,
                      onChanged: (value) => setState(() {
                        _provider = value;
                        _slot = null;
                      }),
                      title: Text(provider.name),
                      subtitle: Text(
                        '${provider.specialty} · ${provider.yearsExperience} years\n'
                        '${provider.consultationMode.replaceAll('_', ' ')} · '
                        '${provider.durationMinutes} minutes',
                      ),
                      isThreeLine: true,
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
                onPressed: _slot == null ? null : _book,
                child: const Text('Confirm booking'),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/appointment.dart';
import '../controllers/bookings_cubit.dart';

class Doctor {
  final String name;
  final String specialty;
  final String avatarUrl;

  const Doctor(this.name, this.specialty, this.avatarUrl);
}

class BookConsultationScreen extends StatefulWidget {
  const BookConsultationScreen({super.key});

  @override
  State<BookConsultationScreen> createState() => _BookConsultationScreenState();
}

class _BookConsultationScreenState extends State<BookConsultationScreen> {
  final List<Doctor> _doctors = const [
    Doctor('Dr. Emmanuel Boateng', 'General Practitioner', 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=150&auto=format&fit=crop&q=60'),
    Doctor('Dr. Sarah Mensah', 'Pediatrician', 'https://images.unsplash.com/photo-1594824813573-246434de83fb?w=150&auto=format&fit=crop&q=60'),
    Doctor('Dr. Kenneth Osei', 'Pharmacologist', 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150&auto=format&fit=crop&q=60'),
  ];

  final List<String> _slots = const [
    '9:00 AM', '10:30 AM', '11:00 AM', '1:30 PM', '3:00 PM', '4:30 PM'
  ];

  Doctor? _selectedDoctor;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedSlot;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showConfirmationSheet() {
    if (_selectedDoctor == null || _selectedSlot == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confirm Booking', style: AppTextStyles.heading),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(_selectedDoctor!.avatarUrl),
                    radius: 24,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedDoctor!.name, style: AppTextStyles.subheading),
                      Text(_selectedDoctor!.specialty, style: AppTextStyles.body),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.hairline),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date:', style: AppTextStyles.body),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: AppTextStyles.subheading,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Time:', style: AppTextStyles.body),
                  Text(_selectedSlot!, style: AppTextStyles.subheading),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Create and persist the booking locally
                    final newBooking = Appointment(
                      id: 'BKG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      doctorName: _selectedDoctor!.name,
                      specialty: _selectedDoctor!.specialty,
                      date: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      time: _selectedSlot!,
                      avatarUrl: _selectedDoctor!.avatarUrl,
                      videoLink: 'https://meet.google.com/abc-defg-hij',
                      notes: 'Refill consultation. Please show your Identity Tag at the pharmacy.',
                    );
                    context.read<BookingsCubit>().addBooking(newBooking);

                    // Navigate to Bookings tab on parent shell
                    Navigator.pop(context); // close sheet
                    context.go('/patient/bookings');
                  },
                  child: const Text('Confirm & Book'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Book Consultation', style: AppTextStyles.subheading),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text('Choose Doctor', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  for (final doc in _doctors) ...[
                    _DoctorTile(
                      doctor: doc,
                      selected: _selectedDoctor == doc,
                      onTap: () => setState(() => _selectedDoctor = doc),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 16),
                  Text('Choose Date', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.hairline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 12),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: AppTextStyles.subheading,
                              ),
                            ],
                          ),
                          Text('Change', style: AppTextStyles.label),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Available Time Slots', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _slots.length,
                    itemBuilder: (context, index) {
                      final slot = _slots[index];
                      final selected = _selectedSlot == slot;
                      return InkWell(
                        onTap: () => setState(() => _selectedSlot = slot),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.accent : Colors.transparent,
                            border: Border.all(
                              color: selected ? AppColors.accent : AppColors.hairline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            slot,
                            style: AppTextStyles.label.copyWith(
                              color: selected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedDoctor != null && _selectedSlot != null)
                    ? _showConfirmationSheet
                    : null,
                child: const Text('Continue to Confirm'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  final Doctor doctor;
  final bool selected;
  final VoidCallback onTap;

  const _DoctorTile({
    required this.doctor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(doctor.avatarUrl),
              radius: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor.name, style: AppTextStyles.subheading),
                  Text(doctor.specialty, style: AppTextStyles.body),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.accent)
            else
              const Icon(Icons.circle_outlined, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

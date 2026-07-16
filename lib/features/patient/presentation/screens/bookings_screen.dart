import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/bookings_cubit.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  @override
  void initState() {
    super.initState();
    // Lazy load when screen is first navigated to
    context.read<BookingsCubit>().loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/patient/home');
            }
          },
        ),
        title: Text('My Bookings', style: AppTextStyles.subheading),
      ),
      body: BlocBuilder<BookingsCubit, BookingsState>(
        builder: (context, state) {
          if (state.isLoading && state.appointments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = state.appointments;
          if (appointments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text('No active bookings found.', style: AppTextStyles.body, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: appointments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final appt = appointments[index];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.hairline),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Booking ${appt.id}', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.statusGood.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Confirmed',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.statusGood,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                          backgroundImage: appt.avatarUrl != null ? NetworkImage(appt.avatarUrl!) : null,
                          child: appt.avatarUrl == null
                              ? const Icon(Icons.person, color: AppColors.accent)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appt.doctorName, style: AppTextStyles.subheading),
                              Text(appt.specialty, style: AppTextStyles.body.copyWith(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(appt.date, style: AppTextStyles.body.copyWith(fontSize: 12)),
                          const SizedBox(width: 20),
                          const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(appt.time, style: AppTextStyles.body.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                    if (appt.notes != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Instruction:',
                        style: AppTextStyles.label.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appt.notes!,
                        style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                    if (appt.videoLink != null) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Launching telehealth consultation at ${appt.videoLink}')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.video_camera_front_outlined, size: 16, color: AppColors.accent),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Telehealth Video Call Link Ready',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 16, color: AppColors.accent),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.hairline, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reschedule request sent to clinic.')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.hairline),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Reschedule'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              context.read<BookingsCubit>().removeBooking(appt.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Appointment cancelled successfully.'),
                                  backgroundColor: AppColors.statusBad,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.statusBad,
                              side: BorderSide(color: AppColors.statusBad.withValues(alpha: 0.3)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

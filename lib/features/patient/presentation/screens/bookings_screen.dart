import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../controllers/bookings_cubit.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key, this.isProviderWorkspace = false});
  final bool isProviderWorkspace;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _formatStamp(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} · $hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _decide(String id, String status) async {
    try {
      await context.read<BookingsCubit>().decideBooking(id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'confirmed'
            ? 'Appointment accepted. The patient can now see your response.'
            : 'Appointment declined. The patient can now see your response.'),
      ));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Lazy load when screen is first navigated to
    context.read<BookingsCubit>().loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    final isProvider = widget.isProviderWorkspace;
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
        title: Text(isProvider ? 'Patient requests' : 'My Bookings',
            style: AppTextStyles.subheading),
      ),
      body: BlocBuilder<BookingsCubit, BookingsState>(
        builder: (context, state) {
          if (state.isLoading && state.appointments.isEmpty) {
            return const SkeletonList(itemCount: 5);
          }
          if (state.error != null && state.appointments.isEmpty) {
            return Center(
              child: FilledButton.icon(
                onPressed: () => context.read<BookingsCubit>().refresh(),
                icon: const Icon(Icons.refresh),
                label: Text(state.error!),
              ),
            );
          }

          final appointments = state.appointments;
          if (appointments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text('No active bookings found.',
                        style: AppTextStyles.body, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<BookingsCubit>().refresh(),
            child: ListView.separated(
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
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Booking ${appt.id}',
                              style: AppTextStyles.label
                                  .copyWith(color: AppColors.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (appt.status == 'cancelled'
                                      ? AppColors.statusBad
                                      : appt.status == 'pending'
                                          ? Colors.orange
                                          : AppColors.statusGood)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              appt.status == 'pending'
                                  ? 'Awaiting review'
                                  : appt.status[0].toUpperCase() +
                                      appt.status.substring(1),
                              style: AppTextStyles.label.copyWith(
                                color: appt.status == 'cancelled'
                                    ? AppColors.statusBad
                                    : appt.status == 'pending'
                                        ? Colors.orange.shade800
                                        : AppColors.statusGood,
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
                            backgroundColor:
                                AppColors.accent.withValues(alpha: 0.1),
                            backgroundImage: appt.avatarUrl != null
                                ? NetworkImage(appt.avatarUrl!)
                                : null,
                            child: appt.avatarUrl == null
                                ? const Icon(Icons.person,
                                    color: AppColors.accent)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appt.doctorName,
                                  style: AppTextStyles.subheading,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  appt.specialty,
                                  style:
                                      AppTextStyles.body.copyWith(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(appt.date,
                                style:
                                    AppTextStyles.body.copyWith(fontSize: 12)),
                            const Icon(Icons.access_time,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(appt.time,
                                style:
                                    AppTextStyles.body.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      if (appt.notes != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Instruction:',
                          style: AppTextStyles.label.copyWith(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appt.notes!,
                          style: AppTextStyles.body.copyWith(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                      if (appt.videoLink != null) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Launching telehealth consultation at ${appt.videoLink}')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.video_camera_front_outlined,
                                    size: 16, color: AppColors.accent),
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
                                Icon(Icons.chevron_right,
                                    size: 16, color: AppColors.accent),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Request timeline',
                                style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            _TimelineRow(
                              icon: Icons.send_outlined,
                              title: 'Appointment requested',
                              stamp: appt.requestedAt == null
                                  ? 'Time not available'
                                  : _formatStamp(appt.requestedAt!),
                              complete: true,
                            ),
                            _TimelineRow(
                              icon: Icons.fact_check_outlined,
                              title: appt.status == 'pending'
                                  ? (isProvider
                                      ? 'Waiting for your review'
                                      : 'Waiting for provider review')
                                  : appt.status == 'confirmed'
                                      ? 'Accepted by provider'
                                      : 'Provider response received',
                              stamp: appt.respondedAt == null
                                  ? 'Pending'
                                  : _formatStamp(appt.respondedAt!),
                              complete: appt.respondedAt != null,
                            ),
                            if (appt.decisionNote?.isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(appt.decisionNote!,
                                    style: AppTextStyles.body
                                        .copyWith(fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.hairline, height: 1),
                      const SizedBox(height: 12),
                      if (isProvider && appt.status == 'pending')
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _decide(appt.id, 'cancelled'),
                                child: const Text('Decline'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _decide(appt.id, 'confirmed'),
                                icon: const Icon(Icons.check),
                                label: const Text('Accept'),
                              ),
                            ),
                          ],
                        )
                      else if (!isProvider &&
                          !{'cancelled', 'completed', 'no_show'}
                              .contains(appt.status))
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stackActions = constraints.maxWidth < 300 ||
                                MediaQuery.textScalerOf(context).scale(14) > 18;
                            final rescheduleButton = OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Reschedule request sent to clinic.')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side:
                                    const BorderSide(color: AppColors.hairline),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Reschedule'),
                            );
                            final cancelButton = OutlinedButton(
                              onPressed: () {
                                context
                                    .read<BookingsCubit>()
                                    .removeBooking(appt.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Appointment cancelled successfully.'),
                                    backgroundColor: AppColors.statusBad,
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.statusBad,
                                side: BorderSide(
                                    color: AppColors.statusBad
                                        .withValues(alpha: 0.3)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Cancel'),
                            );
                            if (stackActions) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  rescheduleButton,
                                  const SizedBox(height: 8),
                                  cancelButton,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: rescheduleButton),
                                const SizedBox(width: 10),
                                Expanded(child: cancelButton),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.title,
    required this.stamp,
    required this.complete,
  });
  final IconData icon;
  final String title;
  final String stamp;
  final bool complete;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon,
                size: 17,
                color: complete ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(fontSize: 12)),
                  Text(stamp,
                      style: AppTextStyles.label.copyWith(
                          fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
}

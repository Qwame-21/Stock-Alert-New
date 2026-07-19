import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../core/widgets/top_notice.dart';
import '../controllers/bookings_cubit.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key, this.isProviderWorkspace = false});
  final bool isProviderWorkspace;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _filter = 'live';
  final Set<String> _clearedCancelled = {};

  Future<void> _cancelAppointment(String id) async {
    var category = 'schedule_change';
    final detail = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Cancel appointment?', style: AppTextStyles.heading),
            Text('Tell the provider why you need to cancel.',
                style: AppTextStyles.body),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Reason category'),
              items: const [
                DropdownMenuItem(
                    value: 'schedule_change', child: Text('Schedule changed')),
                DropdownMenuItem(
                    value: 'feeling_better', child: Text('I feel better')),
                DropdownMenuItem(value: 'cost', child: Text('Cost concern')),
                DropdownMenuItem(
                    value: 'provider_change',
                    child: Text('Choose another provider')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) => setSheetState(() => category = value!),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: detail,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Additional detail')),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Keep booking'))),
              const SizedBox(width: 10),
              Expanded(
                  child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Cancel booking'))),
            ]),
          ]),
        ),
      ),
    );
    final reason = detail.text.trim();
    detail.dispose();
    if (confirmed != true || !mounted) return;
    await context.read<BookingsCubit>().removeBooking(
          id,
          category: category,
          reason: reason.isEmpty
              ? 'Cancelled: ${category.replaceAll('_', ' ')}'
              : reason,
        );
  }

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
      showTopNotice(
        context,
        title: status == 'confirmed'
            ? 'Appointment approved'
            : 'Appointment declined',
        message: status == 'confirmed'
            ? 'The patient can now see the confirmed appointment.'
            : 'The patient can now see your response.',
        type: status == 'confirmed'
            ? TopNoticeType.success
            : TopNoticeType.warning,
      );
    } catch (error) {
      if (mounted) {
        showTopNotice(
          context,
          title: 'Could not update appointment',
          message: friendlyNoticeMessage(error),
          type: TopNoticeType.error,
        );
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

          final allAppointments = state.appointments;
          final appointments = allAppointments.where((appointment) {
            if (_clearedCancelled.contains(appointment.id)) return false;
            return switch (_filter) {
              'approved' => appointment.status == 'confirmed',
              'cancelled' => appointment.status == 'cancelled',
              _ => !{'cancelled', 'completed', 'no_show'}
                  .contains(appointment.status),
            };
          }).toList();
          if (allAppointments.isEmpty) {
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
              itemCount: appointments.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(children: [
                    Row(children: [
                      Expanded(
                          child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? AppColors.accent
                                : const Color(0xFFF2F6F5),
                          ),
                          foregroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? Colors.white
                                : AppColors.accent,
                          ),
                          side: const WidgetStatePropertyAll(
                            BorderSide(color: AppColors.accent),
                          ),
                        ),
                        segments: const [
                          ButtonSegment(value: 'live', label: Text('Live')),
                          ButtonSegment(
                              value: 'approved', label: Text('Approved')),
                          ButtonSegment(
                              value: 'cancelled', label: Text('Cancelled')),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (value) =>
                            setState(() => _filter = value.first),
                      )),
                      if (isProvider && _filter == 'cancelled')
                        IconButton(
                          tooltip: 'Clear cancelled bookings',
                          onPressed: appointments.isEmpty
                              ? null
                              : () => setState(() => _clearedCancelled
                                  .addAll(appointments.map((item) => item.id))),
                          icon: const Icon(Icons.cleaning_services_outlined),
                        ),
                    ]),
                    if (appointments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('No $_filter appointments.',
                            style: AppTextStyles.body),
                      ),
                  ]);
                }
                final appt = appointments[index - 1];

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
                            showTopNotice(
                              context,
                              title: 'Opening consultation',
                              message: 'Your secure video room is ready.',
                              type: TopNoticeType.info,
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
                                showTopNotice(
                                  context,
                                  title: 'Reschedule requested',
                                  message:
                                      'The clinic will review your request.',
                                  type: TopNoticeType.info,
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
                              onPressed: () async {
                                try {
                                  await _cancelAppointment(appt.id);
                                  if (!context.mounted) return;
                                  showTopNotice(
                                    context,
                                    title: 'Appointment cancelled',
                                    message:
                                        'The appointment was removed from your schedule.',
                                    type: TopNoticeType.warning,
                                  );
                                } catch (error) {
                                  if (!context.mounted) return;
                                  showTopNotice(
                                    context,
                                    title: 'Could not cancel appointment',
                                    message: friendlyNoticeMessage(error),
                                    type: TopNoticeType.error,
                                  );
                                }
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/liquid_glass_card.dart';
import '../../data/bookings_repository.dart';
import '../../data/models/appointment.dart';

class PatientHomeScreen extends StatelessWidget {
  final String patientName;
  final String patientIdLabel;
  final String qrToken;

  const PatientHomeScreen({
    super.key,
    required this.patientName,
    required this.patientIdLabel,
    required this.qrToken,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good morning,', style: AppTextStyles.body),
                      Text(patientName, style: AppTextStyles.heading),
                    ],
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.push('/patient/search'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: const Icon(Icons.search,
                              color: AppColors.textSecondary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => context.push('/patient/notifications'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: const Icon(Icons.notifications_none,
                              color: AppColors.textSecondary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Tapping the card opens the full payoff Identity Tag screen
              GestureDetector(
                onTap: () => context.push('/register/4'),
                child: LiquidGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified,
                                    size: 16, color: AppColors.statusGood),
                                SizedBox(width: 6),
                                Text('Verified Patient',
                                    style: AppTextStyles.label
                                        .copyWith(color: AppColors.statusGood)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(patientName, style: AppTextStyles.subheading),
                            SizedBox(height: 2),
                            Text('ID: $patientIdLabel',
                                style: AppTextStyles.body),
                          ],
                        ),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: QrImageView(data: qrToken, size: 44),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _ActionTile(
                    icon: Icons.medication_outlined,
                    label: 'Find Medicine',
                    onTap: () => context.push('/patient/search'),
                  ),
                  _ActionTile(
                    icon: Icons.event_available_outlined,
                    label: 'Book Consultation',
                    onTap: () => context.push('/patient/book-consultation'),
                  ),
                  _ActionTile(
                    icon: Icons.location_on_outlined,
                    label: 'Nearby Pharmacies',
                    onTap: () => context.push('/patient/nearby'),
                  ),
                  _ActionTile(
                    icon: Icons.card_giftcard_outlined,
                    label: 'Rewards',
                    onTap: () => context.push('/patient/rewards'),
                  ),
                ],
              ),
              SizedBox(height: 24),
              const _UpcomingReminder(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (idx) {
          switch (idx) {
            case 0:
              context.go('/patient/home');
              break;
            case 1:
              context.go('/patient/nearby');
              break;
            case 2:
              context.go('/patient/bookings');
              break;
            case 3:
              context.go('/patient/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.near_me_outlined),
              selectedIcon: Icon(Icons.near_me),
              label: 'Nearby'),
          NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Bookings'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _UpcomingReminder extends StatefulWidget {
  const _UpcomingReminder();

  @override
  State<_UpcomingReminder> createState() => _UpcomingReminderState();
}

class _UpcomingReminderState extends State<_UpcomingReminder> {
  late final Future<List<Appointment>> _future = BookingsRepository().load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Appointment>>(
      future: _future,
      builder: (context, snapshot) {
        final upcoming = snapshot.data == null || snapshot.data!.isEmpty
            ? null
            : snapshot.data!.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Upcoming reminder', style: AppTextStyles.subheading),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/patient/notifications'),
                  child: const Text('View all'),
                ),
              ],
            ),
            InkWell(
              onTap: () => context.push(
                upcoming == null
                    ? '/patient/book-consultation'
                    : '/patient/bookings',
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.hairline),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          const Icon(Icons.event_available_outlined,
                              color: AppColors.accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  upcoming?.doctorName ??
                                      'No upcoming consultation',
                                  style: AppTextStyles.subheading,
                                ),
                                Text(
                                  upcoming == null
                                      ? 'Book a consultation to create a reminder'
                                      : '${upcoming.specialty} · ${upcoming.date}',
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                          ),
                          if (upcoming != null)
                            Text(upcoming.time, style: AppTextStyles.label),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 22),
            Text(label, style: AppTextStyles.subheading),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/liquid_glass_card.dart';

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
              Text('Upcoming Reminder', style: AppTextStyles.subheading),
              SizedBox(height: 10),
              InkWell(
                onTap: () => context.push('/patient/notifications'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.hairline),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medication_liquid_outlined,
                          color: AppColors.textSecondary, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vitamin C', style: AppTextStyles.subheading),
                            Text('Take 1 tablet', style: AppTextStyles.body),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Tomorrow', style: AppTextStyles.label),
                          Text('9:00 AM', style: AppTextStyles.label),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
              context.go('/patient/search');
              break;
            case 2:
              context.go('/patient/nearby');
              break;
            case 3:
              context.go('/patient/bookings');
              break;
            case 4:
              context.go('/patient/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.near_me_outlined), selectedIcon: Icon(Icons.near_me), label: 'Nearby'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
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


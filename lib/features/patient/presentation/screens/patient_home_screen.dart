import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/account_menu_button.dart';
import '../../../identity_tag/data/identity_card_repository.dart';
import '../../data/bookings_repository.dart';
import '../../data/models/appointment.dart';
import '../widgets/patient_home_widgets.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({
    super.key,
    required this.patientName,
    required this.patientIdLabel,
    required this.qrToken,
  });

  final String patientName;
  final String patientIdLabel;
  final String qrToken;

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  PatientIdentityCardData? _identity;

  @override
  void initState() {
    super.initState();
    IdentityCardRepository().getMine().then((value) {
      if (mounted) setState(() => _identity = value);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final patientName = widget.patientName;
    final heroItems = [
      HeroBannerItem(
        headline: 'Your health comes first',
        supportingText: 'Find medicines nearby and get expert care.',
        buttonLabel: 'Search Now',
        imageUrl: PatientHomeImages.heroPharmacist,
        imageLabel: 'Pharmacist helping a patient',
        imageAlignment: Alignment.centerRight,
        onPressed: () => context.push('/patient/search'),
      ),
      HeroBannerItem(
        headline: 'Expert care, when you need it',
        supportingText: 'Book a trusted consultation from your phone.',
        buttonLabel: 'Book Care',
        imageUrl: PatientHomeImages.doctorTablet,
        imageLabel: 'Doctor preparing a consultation',
        imageAlignment: Alignment.topCenter,
        onPressed: () => context.push('/patient/book-consultation'),
      ),
      HeroBannerItem(
        headline: 'Pharmacies close to you',
        supportingText: 'Compare nearby availability and get directions.',
        buttonLabel: 'View Nearby',
        imageUrl: PatientHomeImages.pharmacyStorefront,
        imageLabel: 'Community pharmacy storefront',
        onPressed: () => context.push('/patient/nearby'),
      ),
    ];

    final quickActions = [
      QuickActionData(
        icon: Icons.medication_outlined,
        label: 'Find Medicine',
        imageUrl: PatientHomeImages.medicineShelves,
        imageLabel: 'Well-stocked pharmacy shelves',
        onTap: () => context.push('/patient/search'),
      ),
      QuickActionData(
        icon: Icons.event_available_outlined,
        label: 'Book Consultation',
        imageUrl: PatientHomeImages.doctorTablet,
        imageLabel: 'Doctor using a tablet',
        imageAlignment: Alignment.topCenter,
        onTap: () => context.push('/patient/book-consultation'),
      ),
      QuickActionData(
        icon: Icons.location_on_outlined,
        label: 'Nearby Pharmacies',
        imageUrl: PatientHomeImages.pharmacyStorefront,
        imageLabel: 'Modern community pharmacy storefront',
        onTap: () => context.push('/patient/nearby'),
      ),
      QuickActionData(
        icon: Icons.card_giftcard_outlined,
        label: 'Rewards',
        imageUrl: PatientHomeImages.rewards,
        imageLabel: 'A wrapped rewards gift',
        onTap: () => context.push('/patient/rewards'),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeHeader(patientName: patientName),
                  const SizedBox(height: 24),
                  HeroCarousel(items: heroItems),
                  const SizedBox(height: 20),
                  PatientIdentityCard(
                    patientName: patientName,
                    patientIdLabel:
                        _identity?.patientId ?? widget.patientIdLabel,
                    qrToken: _identity?.qrToken ?? widget.qrToken,
                    onTap: () => context.push('/patient/profile'),
                  ),
                  const SizedBox(height: 22),
                  QuickActionGrid(actions: quickActions),
                  const SizedBox(height: 26),
                  const _UpcomingReminder(),
                ],
              ),
            ),
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
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.near_me_outlined),
            selectedIcon: Icon(Icons.near_me),
            label: 'Nearby',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.patientName});

  final String patientName;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showAccountMenu = constraints.maxWidth >= 600;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning,',
                    style: AppTextStyles.body.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    patientName,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: AppTextStyles.heading.copyWith(
                      fontSize: constraints.maxWidth < 380 ? 24 : 27,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _HeaderAction(
              semanticLabel: 'Search medicines',
              icon: Icons.search,
              onTap: () => context.push('/patient/search'),
            ),
            const SizedBox(width: 8),
            _HeaderAction(
              semanticLabel: 'Open notifications',
              icon: Icons.notifications_none,
              onTap: () => context.push('/patient/notifications'),
            ),
            if (showAccountMenu) ...[
              const SizedBox(width: 8),
              const AccountMenuButton(
                roleLabel: 'Patient',
                profileRoute: '/patient/profile',
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.semanticLabel,
    required this.icon,
    required this.onTap,
  });

  final String semanticLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.hairline),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, color: AppColors.accent, size: 22),
          ),
        ),
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
            if (snapshot.connectionState == ConnectionState.waiting)
              const SizedBox(
                height: 128,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ReminderCard(
                title: upcoming?.doctorName ?? 'No upcoming consultation',
                subtitle: upcoming == null
                    ? 'Book a consultation to create a reminder.'
                    : '${upcoming.specialty} · ${upcoming.date}',
                trailing: upcoming == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(upcoming.time, style: AppTextStyles.label),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                onTap: () => context.push(
                  upcoming == null
                      ? '/patient/book-consultation'
                      : '/patient/bookings',
                ),
              ),
          ],
        );
      },
    );
  }
}

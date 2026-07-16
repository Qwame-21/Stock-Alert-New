import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/choose_role_screen.dart';
import '../../features/onboarding/presentation/screens/registration_step_one_screen.dart';
import '../../features/onboarding/presentation/screens/registration_step_two_screen.dart';
import '../../features/onboarding/presentation/screens/registration_step_three_screen.dart';
import '../../features/onboarding/presentation/screens/registration_step_four_screen.dart';
import '../../features/onboarding/presentation/screens/login_screen.dart';
import '../../features/onboarding/presentation/controllers/registration_cubit.dart';

import '../../features/patient/presentation/screens/patient_home_screen.dart';
import '../../features/patient/presentation/screens/find_medicine_screen.dart';
import '../../features/patient/presentation/screens/bookings_screen.dart';
import '../../features/patient/presentation/screens/book_consultation_screen.dart';
import '../../features/patient/presentation/screens/rewards_screen.dart';
import '../../features/patient/presentation/screens/patient_profile_screen.dart';
import '../../features/patient/presentation/screens/notifications_screen.dart';
import '../../features/patient/presentation/screens/change_password_screen.dart';

import '../../features/locator/presentation/screens/locator_screen.dart';
import '../../core/widgets/stock_status_badge.dart';

import '../../features/pharmacy/presentation/screens/pharmacy_dashboard_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/pharmacy/presentation/screens/scan_medicine_screen.dart';
import '../../features/pharmacy/presentation/screens/orders_screen.dart';
import '../../features/pharmacy/presentation/screens/reports_screen.dart';
import '../../features/pharmacy/presentation/screens/pharmacy_more_screen.dart';
import '../../features/pharmacy/presentation/screens/inventory_detail_screen.dart';

import '../storage/local_db_service.dart';

// Sample data for routing configuration
// Removed sampleMedicines, using InventoryCubit with sqflite instead.
const samplePharmacies = [
  NearbyPharmacy(
    name: 'Green Pharmacy',
    distanceLabel: '0.4 km away',
    isOpen: true,
    level: StockLevel.inStock,
    previewInventory: ['Amoxicillin 500mg', 'Ibuprofen 400mg'],
  ),
  NearbyPharmacy(
    name: 'MediCare Pharmacy',
    distanceLabel: '0.8 km away',
    isOpen: true,
    level: StockLevel.lowStock,
    previewInventory: ['Paracetamol 500mg', 'Cough Syrup 100ml'],
  ),
  NearbyPharmacy(
    name: 'HealthPlus Pharmacy',
    distanceLabel: '1.2 km away',
    isOpen: false,
    level: StockLevel.outOfStock,
    previewInventory: [],
  ),
];

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    // Bypass auth check in widget tests where platform channels are not mocked
    final isTesting = (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) ||
        WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets');
    if (isTesting) return null;

    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;

      final loggingIn = state.uri.path == '/login';
      final registering = state.uri.path.startsWith('/register') || state.uri.path == '/choose-role';
      final welcoming = state.uri.path == '/';

      // 1. Unauthenticated
      if (session == null) {
        // Check if registration was in progress in sqflite
        final db = LocalDbService();
        final step = await db.getRegistrationStep();
        final savedState = await db.getRegistrationState();
        final role = savedState?['role'];

        if (step != null && welcoming) {
          if (step == 1) return '/register/2';
          if (step == 2) return role == 'patient' ? '/register/3' : '/register/4';
          if (step == 3) return '/register/4';
        }

        if (loggingIn || registering || welcoming) return null;
        return '/';
      }

      // 2. Authenticated — fetch role for routing
      if (welcoming || loggingIn || registering) {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', session.user.id)
            .single();
        final role = profile['role'] as String? ?? 'patient';
        return role == 'pharmacy' ? '/pharmacy/dashboard' : '/patient/home';
      }
    } catch (e) {
      // Default to unauthenticated welcome flow on any errors
      final loggingIn = state.uri.path == '/login';
      final registering = state.uri.path.startsWith('/register') || state.uri.path == '/choose-role';
      final welcoming = state.uri.path == '/';
      if (loggingIn || registering || welcoming) return null;
      return '/';
    }
    return null;
  },
  routes: [
    // Onboarding Branch
    GoRoute(
      path: '/',
      builder: (context, state) => WelcomeScreen(
        onGetStarted: () => context.push('/choose-role'),
      ),
    ),
    GoRoute(
      path: '/choose-role',
      builder: (context, state) => const ChooseRoleScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        // Support ?expired=true query param (session timeout)
        final expired = state.uri.queryParameters['expired'] == 'true';
        // Support extra map with expiredMessage (e.g. post-registration email confirmation)
        final extraMsg = (state.extra is Map)
            ? (state.extra as Map)['expiredMessage'] as String?
            : null;
        return LoginScreen(
          expiredMessage: extraMsg ??
              (expired ? 'Your session expired, please log in again.' : null),
        );
      },
    ),
    GoRoute(
      path: '/register/1',
      builder: (context, state) => const RegistrationStepOneScreen(),
    ),
    GoRoute(
      path: '/register/2',
      builder: (context, state) => const RegistrationStepTwoScreen(),
    ),
    GoRoute(
      path: '/register/3',
      builder: (context, state) => const RegistrationStepThreeScreen(),
    ),
    GoRoute(
      path: '/register/4',
      builder: (context, state) => const RegistrationStepFourScreen(),
    ),

    // Patient Tab Routes
    GoRoute(
      path: '/patient/home',
      builder: (context, state) {
        final cubitState = context.read<RegistrationCubit>().state;
        final name = cubitState.fullName.isNotEmpty ? cubitState.fullName : 'James Mensah';
        return PatientHomeScreen(
          patientName: name,
          patientIdLabel: 'PAT-7X9A-2B4C',
          qrToken: 'stockalert-PAT-7X9A-2B4C-token',
        );
      },
    ),
    GoRoute(
      path: '/patient/search',
      builder: (context, state) => const FindMedicineScreen(),
    ),
    GoRoute(
      path: '/patient/nearby',
      builder: (context, state) {
        final highlight = state.extra as String?;
        return LocatorScreen(
          pharmacies: samplePharmacies,
          highlightPharmacyName: highlight,
        );
      },
    ),
    GoRoute(
      path: '/patient/bookings',
      builder: (context, state) => const BookingsScreen(),
    ),
    GoRoute(
      path: '/patient/profile',
      builder: (context, state) => const PatientProfileScreen(),
    ),

    // Patient Sub-features
    GoRoute(
      path: '/patient/book-consultation',
      builder: (context, state) => const BookConsultationScreen(),
    ),
    GoRoute(
      path: '/patient/rewards',
      builder: (context, state) => const RewardsScreen(),
    ),
    GoRoute(
      path: '/patient/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/patient/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),

    // Pharmacy Tab Routes
    GoRoute(
      path: '/pharmacy/dashboard',
      builder: (context, state) => const PharmacyDashboardScreen(
        inventoryCount: 432,
        expiringSoonCount: 12,
        pendingOrdersCount: 5,
      ),
    ),
    GoRoute(
      path: '/pharmacy/inventory',
      builder: (context, state) => const InventoryScreen(),
    ),
    GoRoute(
      path: '/pharmacy/scan',
      builder: (context, state) => const ScanMedicineScreen(),
    ),
    GoRoute(
      path: '/pharmacy/orders',
      builder: (context, state) => const OrdersScreen(),
    ),
    GoRoute(
      path: '/pharmacy/more',
      builder: (context, state) => const PharmacyMoreScreen(),
    ),

    // Pharmacy Sub-features
    GoRoute(
      path: '/pharmacy/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/pharmacy/inventory/detail',
      builder: (context, state) {
        final name = state.uri.queryParameters['name'] ?? 'Amoxicillin 500mg';
        final expiry = state.uri.queryParameters['expiry'] ?? '2026-10-15';
        return InventoryDetailScreen(
          medicineName: name,
          initialExpiry: expiry,
        );
      },
    ),
  ],
);

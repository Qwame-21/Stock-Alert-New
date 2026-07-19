import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stockalert/features/onboarding/presentation/controllers/registration_cubit.dart';
import 'package:stockalert/features/onboarding/presentation/screens/choose_role_screen.dart';
import 'package:stockalert/features/onboarding/presentation/screens/registration_step_two_screen.dart';
import 'package:stockalert/features/onboarding/presentation/screens/registration_step_four_screen.dart';
import 'package:stockalert/features/locator/data/pharmacy_discovery_repository.dart';
import 'package:stockalert/features/locator/presentation/screens/locator_screen.dart';
import 'package:stockalert/features/patient/data/models/appointment.dart';
import 'package:stockalert/features/patient/presentation/controllers/bookings_cubit.dart';
import 'package:stockalert/features/patient/presentation/screens/bookings_screen.dart';
import 'package:stockalert/core/widgets/stock_status_badge.dart';

Widget _testApp(Widget screen, RegistrationCubit cubit) {
  return BlocProvider.value(
    value: cubit,
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(1.4),
        ),
        child: screen,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('role chooser remains scrollable on a compact display',
      (tester) async {
    final cubit = RegistrationCubit();
    addTearDown(cubit.close);
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_testApp(const ChooseRoleScreen(), cubit));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('registration document step does not overflow', (tester) async {
    final cubit = RegistrationCubit()..setRole('pharmacy');
    addTearDown(cubit.close);
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _testApp(const RegistrationStepTwoScreen(), cubit),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('registration completion step does not overflow', (tester) async {
    final cubit = RegistrationCubit()..setRole('pharmacy');
    addTearDown(cubit.close);
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _testApp(const RegistrationStepFourScreen(), cubit),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('nearby pharmacy card does not overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const pharmacy = DiscoveredPharmacy(
      id: 'pharmacy-1',
      name: 'MediCare Plus Community Pharmacy With A Long Name',
      location: '45 Oxford Street, Osu, Accra, Greater Accra',
      verificationStatus: 'verified',
      medicines: [
        PharmacyMedicine(
          name: 'Medicine',
          quantity: 0,
          stockLevel: StockLevel.outOfStock,
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.4),
          ),
          child: Scaffold(
            body: SizedBox(
              width: 320,
              child: PharmacyResultCard(
                pharmacy: pharmacy,
                selected: false,
                onTap: _noop,
                onDirections: _noop,
                distanceKm: 12.4,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('booking card remains responsive with long details',
      (tester) async {
    final cubit = BookingsCubit();
    addTearDown(cubit.close);
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(1.4),
            ),
            child: BookingsScreen(),
          ),
        ),
      ),
    );
    cubit.emit(const BookingsState(appointments: [
      Appointment(
        id: 'a-very-long-booking-identifier-123456789',
        doctorName: 'Doctor Alexandra Mensah-Williams',
        specialty: 'Consultant in General and Family Medicine',
        date: '30/12/2026',
        time: '10:30 AM',
      ),
    ]));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

void _noop() {}

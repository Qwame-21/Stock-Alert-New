import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/config/supabase_config.dart';
import 'features/onboarding/presentation/controllers/registration_cubit.dart';
import 'features/inventory/presentation/controllers/inventory_cubit.dart';
import 'features/patient/presentation/controllers/bookings_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      // PKCE is required for mobile deep link auth flows.
      // When the user taps the email confirmation link, the OS intercepts
      // stockalert://auth/callback and re-opens the app. supabase_flutter
      // then exchanges the code/token automatically and creates a session.
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const StockAlertApp());
}

class StockAlertApp extends StatelessWidget {
  const StockAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegistrationCubit>(
          create: (_) => RegistrationCubit()..loadSavedProgress(),
        ),
        BlocProvider<InventoryCubit>(
          create: (_) => InventoryCubit(),
        ),
        BlocProvider<BookingsCubit>(
          create: (_) => BookingsCubit(),
        ),
      ],
      child: MaterialApp.router(
        title: 'StockAlert',
        theme: buildAppTheme(),
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

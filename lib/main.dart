import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/api_config.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/storage/local_db_service.dart';
import 'core/sync/sync_manager.dart';
import 'features/onboarding/presentation/controllers/registration_cubit.dart';
import 'features/inventory/presentation/controllers/inventory_cubit.dart';
import 'features/patient/presentation/controllers/bookings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // flutter_dotenv reads through Flutter's asset bundle, so bindings must be
  // ready first. Dart defines remain available for release/CI builds.
  await dotenv.load(fileName: '.env', isOptional: true);

  if (!SupabaseConfig.isConfigured) {
    throw StateError(
      'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY '
      'to .env or pass them with --dart-define.',
    );
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      // PKCE is required for mobile deep link auth flows.
      // When the user taps the email confirmation link, the OS intercepts
      // stockalert://auth/callback and re-opens the app. supabase_flutter
      // then exchanges the code/token automatically and creates a session.
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const StockAlertApp());
  if (ApiConfig.backgroundSyncEnabled) {
    unawaited(SyncManager().attemptSync().catchError((_) {}));
  }
}

class StockAlertApp extends StatefulWidget {
  const StockAlertApp({super.key});

  @override
  State<StockAlertApp> createState() => _StockAlertAppState();
}

class _StockAlertAppState extends State<StockAlertApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
      if (authState.event == AuthChangeEvent.passwordRecovery) {
        appRouter.go('/reset-password');
        return;
      }
      if (authState.event == AuthChangeEvent.signedIn) {
        unawaited(_openPendingPasswordReset());
      }
    });
  }

  Future<void> _openPendingPasswordReset() async {
    final pendingReset = await LocalDbService().read('password_reset_pending');
    if (pendingReset != null) {
      appRouter.go('/reset-password');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

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

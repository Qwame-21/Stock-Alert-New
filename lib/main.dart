import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
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

  // dotenv needs Flutter ready before it can read the asset.
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
      // PKCE handles the email link when it opens the app again.
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
  StreamSubscription<Uri>? _linkSubscription;
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    final isTesting = (!kIsWeb &&
            Platform.environment.containsKey('FLUTTER_TEST')) ||
        WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets');
    if (isTesting) return;
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleAppLink);
    unawaited(_appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleAppLink(uri);
    }));
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

  void _handleAppLink(Uri uri) {
    if (uri.scheme != 'stockalert' ||
        uri.host != 'payments' ||
        uri.path != '/complete') {
      return;
    }
    final reference = uri.queryParameters['reference'];
    if (reference == null || reference.isEmpty) return;
    appRouter.go(
        '/patient/payment-result?reference=${Uri.encodeQueryComponent(reference)}');
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
    _linkSubscription?.cancel();
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
        scrollBehavior: const AppScrollBehavior(),
      ),
    );
  }
}

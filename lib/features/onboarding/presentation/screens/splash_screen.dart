import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/profile_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1, end: 1.025).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _checkSessionAndNavigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Show splash for at least 1.5s for branding/smooth load experience
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      context.go('/welcome');
      return;
    }

    try {
      final profile = await ProfileRepository().getMe();

      final role = profile['role'] as String? ?? 'patient';
      if (mounted) {
        if (role == 'pharmacy') {
          context.go('/pharmacy/dashboard');
        } else if (role == 'provider') {
          context.go('/provider/dashboard');
        } else {
          context.go('/patient/home');
        }
      }
    } catch (_) {
      // In case profile lookup fails (or database error), fallback to Welcome screen
      if (mounted) {
        context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A0B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Image.asset(
              'assets/images/app_brand.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: const Alignment(0, 0.82),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Checking secure pharmacy network...',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

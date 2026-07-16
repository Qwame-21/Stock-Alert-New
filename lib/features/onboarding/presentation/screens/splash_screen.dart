import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
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
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', session.user.id)
          .single();

      final role = profile['role'] as String? ?? 'patient';
      if (mounted) {
        if (role == 'pharmacy') {
          context.go('/pharmacy/dashboard');
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
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_pharmacy,
                  color: AppColors.accent,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'StockAlert',
              style: AppTextStyles.heading.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Checking secure pharmacy network...',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

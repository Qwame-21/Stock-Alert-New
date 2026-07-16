import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const WelcomeScreen({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.58;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Top portion with the photo and a custom jagged edge transition ──
          Stack(
            children: [
              ClipPath(
                clipper: _TornEdgeClipper(),
                child: Container(
                  height: imageHeight,
                  width: double.infinity,
                  color: AppColors.hairline,
                  child: Image.asset(
                    'assets/images/welcome_pharmacy.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              // Subtle dark gradient overlay to blend into the photo
              ClipPath(
                clipper: _TornEdgeClipper(),
                child: Container(
                  height: imageHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Clean bottom content area ────────────────────────────────────
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // App Title
                  Text(
                    'StockAlert',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Tagline
                  Text(
                    'Helping communities access safe medicine.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(flex: 3),
                  // Primary Get Started Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onGetStarted,
                      child: const Text('Get Started'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Legible & tappable secondary Log In option
                  GestureDetector(
                    onTap: () => context.push('/login'),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Log In',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Subtle horizontal home indicator bar
                  Container(
                    width: 140,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a premium jagged/torn-paper zigzag edge at the bottom of the container
class _TornEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 15);

    // Number of zigzag segments across screen width
    const segments = 24;
    final segmentWidth = size.width / segments;

    for (var i = 0; i < segments; i++) {
      final x1 = (i * segmentWidth) + (segmentWidth / 2);
      final y1 = size.height - (i % 2 == 0 ? 5 : 25);
      final x2 = (i + 1) * segmentWidth;
      final y2 = size.height - 15;

      path.quadraticBezierTo(x1, y1, x2, y2);
    }

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

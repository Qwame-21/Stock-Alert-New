import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const WelcomeScreen({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 700;
          final panelHeight = constraints.maxHeight * (compact ? 0.43 : 0.40);

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/welcome_pharmacy.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0.12, -0.18),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.28, 0.64, 1],
                    colors: [
                      Color(0x99000000),
                      Color(0x14000000),
                      Color(0xB8000000),
                      Color(0xE6000000),
                    ],
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'StockAlert',
                            style: AppTextStyles.subheading.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: panelHeight,
                  padding: EdgeInsets.fromLTRB(
                    28,
                    compact ? 28 : 34,
                    28,
                    0,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(96),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Care, connected.',
                          style: AppTextStyles.heading.copyWith(
                            fontSize: compact ? 24 : 27,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Find trusted pharmacies, check medicine availability, '
                          'and manage your care in one secure place.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: compact ? 13 : 14,
                            height: 1.55,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: onGetStarted,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              shape: const StadiumBorder(),
                            ),
                            child: const Text('Get Started'),
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 16),
                        Center(
                          child: TextButton(
                            onPressed: () => context.push('/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: Text.rich(
                              const TextSpan(
                                text: 'Already have an account?  ',
                                children: [
                                  TextSpan(
                                    text: 'Log in',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              style: AppTextStyles.body.copyWith(fontSize: 13),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


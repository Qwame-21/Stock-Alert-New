import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The frosted glass panel used everywhere - identity card, dashboard
/// summaries, floating sheets on the locator map. One widget, reused,
/// so the "liquid glass" look stays consistent instead of every screen
/// rolling its own blur.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.blurSigma = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.glassTint,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

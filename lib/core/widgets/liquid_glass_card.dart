import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Translucent card without backdrop blur.
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadius.card,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          // Main transparent fill.
          Container(
            decoration: BoxDecoration(
              color: AppColors.glassTint,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          // Light along the top makes the card look curved.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radius),
                  topRight: Radius.circular(radius),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // The top border is brighter than the bottom.
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.85), width: 1.5),
                left: BorderSide(
                    color: Colors.white.withValues(alpha: 0.6), width: 1.0),
                right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.5), width: 1.0),
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.35), width: 1.0),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

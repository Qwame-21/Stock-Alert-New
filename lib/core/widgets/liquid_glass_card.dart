import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A crisp translucent card. No backdrop blur is applied.
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
          // base translucent fill
          Container(
            decoration: BoxDecoration(
              color: AppColors.glassTint,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          // the specular highlight - a soft light catching the top edge,
          // this is what makes it read as curved glass rather than a
          // flat tinted panel
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
          // border - brighter along the top than the bottom, matching
          // how light actually falls on a glass edge
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

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A more realistic take on "liquid glass" than a flat translucent tint.
/// Three things make this read as glass instead of a colored rectangle:
///  1. A stronger blur (24 sigma) so whatever sits behind it visibly warps.
///  2. A soft diagonal highlight in the top-left, like light catching a
///     curved surface - this is the detail flat cards are missing.
///  3. A hairline border that's brighter on top than on the bottom, since
///     real glass catches more light on its upper edge.
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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
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
                      Colors.white.withOpacity(0.45),
                      Colors.white.withOpacity(0.0),
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
                  top: BorderSide(color: Colors.white.withOpacity(0.85), width: 1.5),
                  left: BorderSide(color: Colors.white.withOpacity(0.6), width: 1.0),
                  right: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.0),
                  bottom: BorderSide(color: Colors.white.withOpacity(0.35), width: 1.0),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

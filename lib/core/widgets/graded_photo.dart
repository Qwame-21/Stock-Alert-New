import 'package:flutter/material.dart';

/// A sharp photo with a white leading-edge fade scoped to its own bounds.
/// No blur, color filter, opacity veil, or backdrop effect is applied.
class GradedPhoto extends StatelessWidget {
  const GradedPhoto({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius = 22,
    this.fadeEnd = .30,
  });

  factory GradedPhoto.asset(
    String assetName, {
    Key? key,
    required String semanticLabel,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    double borderRadius = 22,
    double fadeEnd = .30,
  }) =>
      GradedPhoto(
        key: key,
        image: AssetImage(assetName),
        semanticLabel: semanticLabel,
        fit: fit,
        alignment: alignment,
        borderRadius: borderRadius,
        fadeEnd: fadeEnd,
      );

  final ImageProvider image;
  final String semanticLabel;
  final BoxFit fit;
  final Alignment alignment;
  final double borderRadius;
  final double fadeEnd;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: image,
              fit: fit,
              alignment: alignment,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFF3F5F4),
                child: Center(
                  child: Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin:
                          isRtl ? Alignment.centerRight : Alignment.centerLeft,
                      end: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                      colors: const [
                        Colors.white,
                        Color(0x00FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                      stops: [0, fadeEnd.clamp(.25, .35), 1],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

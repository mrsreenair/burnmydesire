import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A physical card lying on the paper: white, rounded, soft shadow, and
/// a slight tilt. The Canopi-style collage is built from these.
class TiltCard extends StatelessWidget {
  const TiltCard({
    super.key,
    required this.child,
    this.tiltDegrees = 0,
    this.color = AppColors.paperHigh,
    this.radius = 18,
    this.padding,
  });

  final Widget child;
  final double tiltDegrees;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tiltDegrees * math.pi / 180,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: AppColors.cardShadow(),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// The little tilted card stack used in empty states and heroes —
/// Canopi's "collections will appear here" mark.
class CardFan extends StatelessWidget {
  const CardFan({super.key, required this.cards, this.size = 72});

  /// 2–4 widgets, each rendered as a small tilted card.
  final List<Widget> cards;
  final double size;

  @override
  Widget build(BuildContext context) {
    const tilts = [-8.0, 4.0, -2.0, 7.0];
    // Spread scales with card size so every card's face stays visible.
    final shifts = [
      Offset(-size * 0.9, size * 0.06),
      Offset(0, -size * 0.1),
      Offset(size * 0.9, size * 0.03),
      Offset(size * 1.7, size * 0.1),
    ];
    return SizedBox(
      height: size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < cards.length; i++)
            Transform.translate(
              offset: shifts[i % shifts.length],
              child: TiltCard(
                tiltDegrees: tilts[i % tilts.length],
                radius: 14,
                child: SizedBox(
                  width: size,
                  height: size * 1.15,
                  child: Center(child: cards[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

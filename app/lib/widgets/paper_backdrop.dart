import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The signature Canopi-style backdrop: warm paper with soft pastel
/// washes breathing in the corners — mint top-right, peach top-left.
/// Static and cheap; the "life" of the page comes from the cards on it.
class PaperBackdrop extends StatelessWidget {
  const PaperBackdrop({super.key, required this.child, this.warmth = 1.0});

  final Widget child;

  /// 0–1: how visible the pastel washes are (ritual-adjacent screens can
  /// warm the page up with a peach cast).
  final double warmth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.paper),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1.2, -1.2),
              radius: 1.4,
              colors: [
                AppColors.washMint.withValues(alpha: 0.8 * warmth),
                AppColors.washMint.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-1.3, -0.9),
              radius: 1.3,
              colors: [
                AppColors.washPeach.withValues(alpha: 0.9 * warmth),
                AppColors.washPeach.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

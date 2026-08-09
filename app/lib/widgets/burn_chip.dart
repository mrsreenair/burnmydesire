import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// Selectable pill used in the goal / category pickers. Selection pops
/// with a spring and lights the border like a struck match.
class BurnChip extends StatelessWidget {
  const BurnChip({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String emoji;
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!selected);
      },
      child: AnimatedScale(
        scale: selected ? 1.0 : 0.98,
        duration: Motion.fast,
        curve: Motion.spring,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.paperHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : AppColors.ink.withValues(alpha: 0.06),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected ? null : AppColors.cardShadow(opacity: 0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.ink : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

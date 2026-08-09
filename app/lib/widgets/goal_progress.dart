import 'package:flutter/material.dart';

import '../data/financial_goal.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';

/// The destination card: how far the protected total has travelled
/// toward the user's own goal. This is the line that turns "you saved
/// money" into "you're getting somewhere".
class GoalProgress extends StatelessWidget {
  const GoalProgress({
    super.key,
    required this.goal,
    required this.protectedCents,
    this.onTap,
  });

  final FinancialGoal goal;
  final int protectedCents;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = goal.percentOf(protectedCents);
    final reached = goal.reachedBy(protectedCents);
    return Material(
      color: AppColors.money.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.money.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(goal.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      goal.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    reached ? 'Reached!' : '$percent%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.money,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (protectedCents / goal.targetCents).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.money.withValues(alpha: 0.15),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.money),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reached
                    ? 'You protected your way to it — '
                        '${formatMoney(goal.targetCents)} and past.'
                    : '${formatMoney(protectedCents)} of '
                        '${formatMoney(goal.targetCents)} protected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

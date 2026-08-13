import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// "How your free trial works" — today, the reminder, the charge.
///
/// Lifted from Monarch and Centr, who both spend a third of their paywall
/// on exactly this. It answers the only question standing between someone
/// and a trial: *when do you take my money, and will I see it coming?*
/// Spelling that out costs nothing and is the difference between a trial
/// that feels like a trap and one that doesn't.
class TrialTimeline extends StatelessWidget {
  const TrialTimeline({super.key, required this.days, required this.priceLine});

  /// Length of the free trial in days.
  final int days;

  /// What happens at the end, in the store's own words — e.g.
  /// "€19.99/year starts".
  final String priceLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Apple requires the reminder email at 24h; saying so is free trust.
    final reminderDay = days > 1 ? days - 1 : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      decoration: BoxDecoration(
        color: AppColors.paperHigh,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow(opacity: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How the free trial works',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _Step(
            icon: Icons.lock_open_rounded,
            title: 'Today',
            body: 'Everything unlocks. You pay nothing.',
            first: true,
          ),
          if (reminderDay != null)
            _Step(
              icon: Icons.notifications_none_rounded,
              title: 'Day $reminderDay',
              body: 'Apple emails you before the trial ends.',
            ),
          _Step(
            icon: Icons.event_available_rounded,
            title: 'Day $days',
            body: priceLine,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.body,
    this.first = false,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The rail: a continuous line through the dots, so the three
          // moments read as one timeline rather than three bullets.
          Column(
            children: [
              Container(
                width: 2,
                height: 6,
                color: first ? Colors.transparent : AppColors.hairline,
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: last
                      ? AppColors.accent.withValues(alpha: 0.14)
                      : AppColors.money.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: last ? AppColors.accent : AppColors.moneyDeep,
                ),
              ),
              if (!last)
                Expanded(child: Container(width: 2, color: AppColors.hairline)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMid,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

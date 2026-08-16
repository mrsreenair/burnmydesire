import 'package:flutter/material.dart';

import '../data/financial_goal.dart';
import '../data/market_data.dart';
import '../models/burn_target.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
import 'ember_ui.dart';

/// The damage, priced in the thing the user actually said they wanted.
///
/// A projection into an index fund is a fact you read and forget; every
/// projection screen worth copying (Rocket Money's "you're only £1,995
/// away", Monzo's pots, Finch's named goals) anchors the number to
/// something the person chose themselves. So the headline here is not
/// what the money becomes — it is what this purchase takes away:
/// a measurable slice of their own goal.
///
/// The market projection still matters, so it stays — as one quiet line
/// with the assumptions and the legal text behind an ⓘ. Seven competing
/// blocks became three.
class GoalDamageCard extends StatelessWidget {
  const GoalDamageCard({
    super.key,
    required this.target,
    required this.goal,
    required this.protectedCents,
    required this.years,
    this.fund,
    this.onDetails,
  });

  final BurnTarget target;
  final FinancialGoal goal;

  /// What they've already protected — where the bar stands today.
  final int protectedCents;

  final int years;
  final FundSeries? fund;

  /// Opens the assumptions sheet (fund, horizon, disclosure).
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = target.priceCents;

    // The slice of the dream this one purchase is worth. Uncapped on
    // purpose: a desire bigger than the whole goal should say so.
    final sliceExact = goal.targetCents <= 0
        ? 0.0
        : price * 100 / goal.targetCents;
    final slice = sliceExact >= 1 ? sliceExact.round() : sliceExact.ceil();

    final now = goal.percentOf(protectedCents);
    final after = goal.percentOf(protectedCents + price);
    final gain = after - now;

    final projected = fund != null
        ? fund!.projectedValueCents(price, years)
        : futureValueCents(price, years: years);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.paperHigh,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            // A subscription isn't a purchase, and the year is the unit
            // being priced here — say so rather than letting the number
            // look like the whole cost of the thing.
            target.isSubscription
                ? 'A year of this costs you'
                : 'This purchase costs you',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 6),
          // The headline: a share of their own dream, not a market number.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: slice.toDouble()),
            duration: Motion.slow,
            curve: Motion.easeOut,
            builder: (context, v, _) => GradientText(
              '${v.round()}%',
              style: theme.textTheme.displayMedium,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'of ${goal.emoji} ${goal.name}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),

          // Where they stand, and where burning this would put them. The
          // gain is drawn ON the bar rather than described, so the reward
          // for resisting is visible before they've done it.
          _GoalBar(now: now, after: after),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatMoney(protectedCents),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.money,
                ),
              ),
              Text(
                formatMoney(goal.targetCents),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.money.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              // Deliberately no second percentage. The headline rounds
              // (3.75% reads as 4%) and percentOf truncates, so quoting
              // both put "4%" and "3%" on the same card for the same
              // quantity — small, but it makes the whole number look
              // made up. Money here, the movement on the bar.
              gain > 0 || protectedCents == 0
                  ? 'Burning it takes you to '
                        '${formatMoney(protectedCents + price)} of '
                        '${formatMoney(goal.targetCents)}.'
                  : 'Burning it keeps ${formatMoney(price)} toward it.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.moneyDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (target.plan != null) ...[
            const SizedBox(height: 10),
            Text(
              // One line, not the old paragraph: the instalment maths is a
              // twist of the knife, not the point of the screen.
              'On instalments you\'d pay '
              '${formatMoney(target.plan!.totalPaidCents)} — '
              '${formatMoney(target.plan!.overpaymentCents(price))} more '
              'than it costs.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.flame,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 14),
          // The market case, demoted to one line. Everything technical —
          // which fund, how many years, the legal text — lives behind
          // this, the way Nutmeg hides projections behind "About this".
          GestureDetector(
            onTap: onDetails,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Invested instead, about ${formatMoney(projected)} '
                    'in $years years',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.textLow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-tone progress: what's already protected, then the slice this burn
/// would add, drawn lighter so it reads as "could be" rather than "is".
class _GoalBar extends StatelessWidget {
  const _GoalBar({required this.now, required this.after});

  final int now;
  final int after;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Motion.slow,
          curve: Motion.easeOut,
          builder: (context, t, _) => SizedBox(
            height: 14,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.field,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                // The "could be" segment sits underneath, so the solid
                // one paints over its left edge and they read as one bar.
                Container(
                  width: w * (after / 100) * t,
                  decoration: BoxDecoration(
                    color: AppColors.money.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                Container(
                  width: w * (now / 100) * t,
                  decoration: BoxDecoration(
                    gradient: AppColors.wealthGradient,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

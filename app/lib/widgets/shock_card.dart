import 'package:flutter/material.dart';

import '../data/market_data.dart';
import '../models/burn_target.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
import '../widgets/ember_ui.dart';

/// The rational punch: one bold number, everything else quiet.
/// Forward-looking: what the money could become by year X if invested
/// today and the asset repeats its real historical average return.
class ShockCard extends StatelessWidget {
  const ShockCard({
    super.key,
    required this.target,
    required this.years,
    required this.onYearsChanged,
    this.market,
    this.fundIndex = 0,
    this.onFundChanged,
  });

  static const int maxYears = 30;

  final BurnTarget target;
  final int years;
  final ValueChanged<int> onYearsChanged;
  final MarketData? market;
  final int fundIndex;
  final ValueChanged<int>? onFundChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = target.priceCents;
    final fund = market?.funds[fundIndex];
    final targetYear = DateTime.now().year + years;

    final int shown;
    final double rate;
    if (fund != null) {
      shown = fund.projectedValueCents(price, years);
      rate = fund.fullHistoryCagr;
    } else {
      shown = futureValueCents(price, years: years);
      rate = kDefaultAnnualRate;
    }
    final plan = target.plan;
    final pct = (rate * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.paperHigh,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Invested today instead, this ${formatMoney(price)} could be',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 10),
          // The number itself: ember gradient, animated between values so
          // dragging the slider makes the damage visibly grow or shrink.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: shown.toDouble()),
            duration: Motion.slow,
            curve: Motion.easeOut,
            builder: (context, v, _) => GradientText(
              formatMoney(v.round()),
              style: theme.textTheme.displayMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fund != null
                ? 'by $targetYear in ${fund.name} — real '
                      '${fund.yearsAvailable}-year average: $pct%/yr'
                : 'by $targetYear at $pct%/yr',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 20),
          if (market != null && onFundChanged != null) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < market!.funds.length; i++) ...[
                    ChoiceChip(
                      label: Text(market!.funds[i].name),
                      selected: i == fundIndex,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: i == fundIndex
                            ? AppColors.accent
                            : AppColors.textMid,
                      ),
                      onSelected: (_) => onFundChanged!(i),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: years.toDouble(),
                  min: 1,
                  max: maxYears.toDouble(),
                  divisions: maxYears - 1,
                  label: '$years y',
                  onChanged: (v) => onYearsChanged(v.round()),
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  years == 1 ? '1 year' : '$years years',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          if (plan != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.flame.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.flame.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'On installments it\'s worse: ${plan.months} × '
                '${formatMoney(plan.monthlyCents)} = '
                '${formatMoney(plan.totalPaidCents)} paid '
                '(${formatMoney(plan.overpaymentCents(price))} extra), '
                'a true cost of '
                '${formatMoney(plan.trueCostCents(price, years: years, annualRate: rate))}.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            fund != null
                ? 'Projection assumes ${fund.name} (${fund.ticker}) repeats '
                      'its real ${fund.yearsAvailable}-year average total '
                      'return, dividends included, data to '
                      '${market!.asOfLabel}. Past performance doesn\'t '
                      'guarantee future results. Not investment advice.'
                : 'Assumes ${(kDefaultAnnualRate * 100).toStringAsFixed(0)}% '
                      'avg. annual return (historical market average). Not a '
                      'guarantee or investment advice.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

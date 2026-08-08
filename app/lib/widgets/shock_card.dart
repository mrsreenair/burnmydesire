import 'package:flutter/material.dart';

import '../data/market_data.dart';
import '../models/burn_target.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Invested today instead, this ${formatEuros(price)} could be',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              formatEuros(shown),
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              fund != null
                  ? 'by $targetYear in ${fund.name} — real '
                      '${fund.yearsAvailable}-year average: $pct%/yr'
                  : 'by $targetYear at $pct%/yr',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (market != null && onFundChanged != null) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < market!.funds.length; i++) ...[
                      ChoiceChip(
                        label: Text(market!.funds[i].name),
                        selected: i == fundIndex,
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
              const SizedBox(height: 16),
              Text(
                'On installments it\'s worse: ${plan.months} × '
                '${formatEuros(plan.monthlyCents)} = '
                '${formatEuros(plan.totalPaidCents)} paid '
                '(${formatEuros(plan.overpaymentCents(price))} extra), '
                'a true cost of '
                '${formatEuros(plan.trueCostCents(price, years: years, annualRate: rate))}.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

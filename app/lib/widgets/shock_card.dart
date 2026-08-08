import 'package:flutter/material.dart';

import '../data/market_data.dart';
import '../models/burn_target.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';

/// The rational punch: one bold number, everything else quiet.
/// The number is real market history — what the money would actually be
/// worth today had it been invested [years] ago in the selected fund.
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

    final int shown;
    final double rate;
    if (fund != null) {
      shown = fund.valueTodayCents(price, years);
      rate = fund.realizedCagr(years);
    } else {
      shown = futureValueCents(price, years: years);
      rate = kDefaultAnnualRate;
    }
    final plan = target.plan;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Invested instead, this ${formatEuros(price)} would be',
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
              fund != null ? _fundLine(fund, rate) : 'in $years years',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (market != null && onFundChanged != null) ...[
              SegmentedButton<int>(
                segments: [
                  for (var i = 0; i < market!.funds.length; i++)
                    ButtonSegment(
                        value: i, label: Text(market!.funds[i].name)),
                ],
                selected: {fundIndex},
                onSelectionChanged: (s) => onFundChanged!(s.first),
              ),
              const SizedBox(height: 8),
            ],
            SegmentedButton<int>(
              segments: [
                for (final h in kHorizons)
                  ButtonSegment(value: h, label: Text('$h y')),
              ],
              selected: {years},
              onSelectionChanged: (s) => onYearsChanged(s.first),
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
                  ? 'Real ${fund.ticker} total return incl. dividends, data '
                      'to ${market!.asOfLabel}. Past performance doesn\'t '
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

  /// e.g. "in the S&P 500 since 2006 — its real record: 10.2%/yr" (clamps
  /// to the fund's full history when it's shorter than the horizon).
  String _fundLine(FundSeries fund, double rate) {
    final since = fund.investmentYear(years);
    final clamped = !fund.covers(years);
    final pct = (rate * 100).toStringAsFixed(1);
    return clamped
        ? 'in the ${fund.name} since $since (all its history) — '
            'real record: $pct%/yr'
        : 'in the ${fund.name} since $since — its real record: $pct%/yr';
  }
}

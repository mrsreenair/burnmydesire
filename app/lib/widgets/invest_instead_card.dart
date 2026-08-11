import 'package:flutter/material.dart';

import '../data/market_data.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/format_utils.dart';
import 'ember_ui.dart';

/// What the money could do if it went to work instead — the second half
/// of the argument. The goal card says what this purchase takes; this
/// says what the same money is capable of.
///
/// A dropdown to choose the market and a slider for the horizon, the way
/// Stake and Plum let you move the inputs and watch the number answer.
/// One number at a time rather than a list of fourteen: the whole point
/// of this redesign was fewer things shouting at once.
///
/// Three honesty rules, all load-bearing:
///  * Indices sit first in the menu and one is always the default. A
///    single stock's past 30 years is the most cherry-pickable number in
///    finance, and opening on Nvidia would be a con.
///  * Individual companies are never projected FORWARD. Compounding
///    Tesla's 40.9%/yr for another twenty years turns €150 into €142,787
///    — arithmetically correct, completely fictional, and printing it
///    would discredit every other number on the screen. They show real
///    history instead: what this money put in years ago would actually be
///    worth today. Same motivating effect, except it happened.
///  * The two groups are labelled in the menu, so nobody reads a company
///    as a tip.
class InvestInsteadCard extends StatelessWidget {
  const InvestInsteadCard({
    super.key,
    required this.priceCents,
    required this.years,
    required this.onYearsChanged,
    required this.funds,
    required this.selected,
    required this.onSelect,
    this.maxYears = 30,
    this.onDetails,
  });

  final int priceCents;
  final int years;
  final ValueChanged<int> onYearsChanged;
  final List<FundSeries> funds;
  final int selected;
  final ValueChanged<int> onSelect;
  final int maxYears;
  final VoidCallback? onDetails;

  static const _indexIds = {'sp500', 'nasdaq', 'world', 'nifty', 'ftse', 'dax'};

  static bool _isIndex(FundSeries f) => _indexIds.contains(f.id);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (funds.isEmpty) return const SizedBox.shrink();

    final index = selected.clamp(0, funds.length - 1);
    final fund = funds[index];
    final backward = !_isIndex(fund);

    final value = backward
        ? fund.valueTodayCents(priceCents, years)
        : fund.projectedValueCents(priceCents, years);
    final rate = backward ? fund.realizedCagr(years) : fund.fullHistoryCagr;
    final multiple = priceCents <= 0 ? 0.0 : value / priceCents;

    final indices = <int>[];
    final companies = <int>[];
    for (var i = 0; i < funds.length; i++) {
      (_isIndex(funds[i]) ? indices : companies).add(i);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.paperHigh,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.cardShadow(opacity: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Or put it to work',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),

          // The market picker. Headers are disabled entries rather than a
          // flat list, so the difference between a fund and one company
          // survives the collapse into a dropdown.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.field.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: index,
                isExpanded: true,
                borderRadius: BorderRadius.circular(18),
                icon: const Icon(Icons.expand_more_rounded),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
                items: [
                  const DropdownMenuItem<int>(
                    enabled: false,
                    child: Text(
                      'FUNDS & INDEXES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.textLow,
                      ),
                    ),
                  ),
                  for (final i in indices)
                    DropdownMenuItem<int>(value: i, child: Text(funds[i].name)),
                  if (companies.isNotEmpty) ...[
                    const DropdownMenuItem<int>(
                      enabled: false,
                      child: Text(
                        'SINGLE COMPANIES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textLow,
                        ),
                      ),
                    ),
                    for (final i in companies)
                      DropdownMenuItem<int>(
                        value: i,
                        child: Text(funds[i].name),
                      ),
                  ],
                ],
                onChanged: (i) {
                  if (i != null) onSelect(i);
                },
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            backward
                ? '${formatMoney(priceCents)} put into ${fund.name} in '
                      '${fund.investmentYear(years)} would be worth'
                : '${formatMoney(priceCents)} in ${fund.name} could be',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.toDouble()),
                duration: Motion.slow,
                curve: Motion.easeOut,
                builder: (context, v, _) => Text(
                  formatMoney(v.round()),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.moneyDeep,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '×${multiple.toStringAsFixed(multiple >= 10 ? 0 : 1)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.money,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            backward
                ? '${fund.ticker} · real history, '
                      '${(rate * 100).toStringAsFixed(1)}%/yr'
                : '${fund.ticker} · if it repeats its '
                      '${fund.yearsAvailable}-year average of '
                      '${(rate * 100).toStringAsFixed(1)}%/yr',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMid,
            ),
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              const SectionLabel('Years'),
              const Spacer(),
              Text(
                years == 1 ? '1 year' : '$years years',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          Slider(
            value: years.toDouble(),
            min: 1,
            max: maxYears.toDouble(),
            divisions: maxYears - 1,
            label: '$years y',
            onChanged: (v) => onYearsChanged(v.round()),
          ),

          const SizedBox(height: 2),
          GestureDetector(
            onTap: onDetails,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    backward
                        ? 'One company can also go to zero — a fund spreads '
                              'that risk. Past returns, not a forecast. '
                              'Nothing here is advice.'
                        : 'Past returns, not a forecast. Nothing here is '
                              'advice.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textLow,
                      height: 1.35,
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

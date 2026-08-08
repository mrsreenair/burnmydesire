import 'package:flutter/material.dart';

import '../models/burn_target.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';

/// The rational punch: one bold number, everything else quiet.
class ShockCard extends StatelessWidget {
  const ShockCard({
    super.key,
    required this.target,
    required this.years,
    required this.onYearsChanged,
  });

  final BurnTarget target;
  final int years;
  final ValueChanged<int> onYearsChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = target.priceCents;
    final future = futureValueCents(price, years: years);
    final plan = target.plan;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This ${formatEuros(price)} purchase is stealing',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              formatEuros(future),
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              'from your $years-year wealth',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
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
                '${formatEuros(plan.trueCostCents(price, years: years))}.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Assumes ${(kDefaultAnnualRate * 100).toStringAsFixed(0)}% avg. '
              'annual return (historical market average). Not a guarantee '
              'or investment advice.',
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

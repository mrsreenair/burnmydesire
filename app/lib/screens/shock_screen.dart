import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/market_data.dart';
import '../data/reflection.dart';
import '../models/burn_target.dart';
import '../providers/db_providers.dart';
import '../providers/financial_goal_provider.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/math_utils.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/ember_ui.dart';
import '../widgets/goal_damage_card.dart';
import '../widgets/invest_instead_card.dart';
import '../widgets/shock_card.dart';
import 'burn_screen.dart';
import 'financial_goal_screen.dart';

class ShockScreen extends ConsumerStatefulWidget {
  const ShockScreen({super.key, required this.target, this.forGrowth = false});

  final BurnTarget target;

  /// User said this purchase builds their future: soften the framing.
  final bool forGrowth;

  @override
  ConsumerState<ShockScreen> createState() => _ShockScreenState();
}

class _ShockScreenState extends ConsumerState<ShockScreen> {
  int _years = kDefaultHorizonYears;
  int _fund = 0;

  /// Fund, horizon and the legal text — everything technical, one tap
  /// away rather than stacked on the card.
  Future<void> _showAssumptions(List<FundSeries> funds, String? asOf) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => _AssumptionsSheet(
          funds: funds,
          asOf: asOf,
          years: _years,
          fundIndex: _fund,
          onYears: (y) {
            setSheetState(() {});
            setState(() => _years = y);
          },
          onFund: (f) {
            setSheetState(() {});
            setState(() => _fund = f);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketDataProvider).value;
    final funds = ref.watch(relevantFundsProvider);
    final goal = ref.watch(financialGoalProvider).value;
    final protected = ref.watch(protectedCentsProvider);
    // The headline card always quotes the index, never whatever the user
    // is poking at in the picker below. Selecting Nvidia there must not
    // make the summary line say €95,536 — that number is a fantasy, and
    // the card above the fold is the one people believe. `funds` is
    // index-first (MarketData.fundsFor), so first is always a fund.
    final headlineFund = funds.isNotEmpty ? funds.first : null;

    return Scaffold(
      appBar: AppBar(title: const Text('The damage')),
      extendBodyBehindAppBar: false,
      body: PaperBackdrop(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // A re-burn of something they were interviewed
                        // about: their own words, back. Nobody argues
                        // with their own words.
                        if (widget.target.burnNumber > 1 &&
                            widget.target.reflection.isNotEmpty) ...[
                          Reveal(
                            child: _LastTimeCard(
                              qa: widget.target.reflection.first,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (widget.forGrowth) ...[
                          Reveal(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.money.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.money.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Text(
                                '🌱  Tools that truly grow your skills can be '
                                'worth buying. Decide with a clear head — '
                                'here\'s what it costs either way.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Reveal(
                          delay: const Duration(milliseconds: 80),
                          // With a goal saved, the damage is priced in the
                          // user's own dream. Without one there's nothing
                          // personal to anchor to, so the market card
                          // stands in — and offers to fix that.
                          child: goal != null
                              ? GoalDamageCard(
                                  target: widget.target,
                                  goal: goal,
                                  protectedCents: protected,
                                  years: _years,
                                  fund: headlineFund,
                                  onDetails: () => _showAssumptions(
                                    funds,
                                    market?.asOfLabel,
                                  ),
                                )
                              : ShockCard(
                                  target: widget.target,
                                  years: _years,
                                  onYearsChanged: (y) =>
                                      setState(() => _years = y),
                                  funds: funds,
                                  asOf: market?.asOfLabel,
                                  fundIndex: _fund,
                                  onFundChanged: (f) =>
                                      setState(() => _fund = f),
                                ),
                        ),
                        // The other half of the argument: what the same
                        // money is capable of. Only under the goal card —
                        // the fallback ShockCard already carries the
                        // market, and two pickers would just compete.
                        if (goal != null && funds.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Reveal(
                            delay: const Duration(milliseconds: 140),
                            child: InvestInsteadCard(
                              priceCents: widget.target.priceCents,
                              years: _years,
                              onYearsChanged: (y) => setState(() => _years = y),
                              maxYears: ShockCard.maxYears,
                              funds: funds,
                              selected: _fund,
                              onSelect: (i) => setState(() => _fund = i),
                              onDetails: () =>
                                  _showAssumptions(funds, market?.asOfLabel),
                            ),
                          ),
                        ],
                        if (goal == null) ...[
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                emberRoute(
                                  const FinancialGoalScreen(inSetup: false),
                                ),
                              );
                              ref.invalidate(financialGoalProvider);
                            },
                            child: const Text('Name what you\'re saving for →'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Reveal(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EmberButton(
                      label: widget.forGrowth
                          ? 'Burn it anyway'
                          : 'Burn this desire',
                      icon: Icons.local_fire_department,
                      kind: PillKind.fire,
                      onPressed: () => Navigator.of(
                        context,
                      ).push(fireRoute(BurnScreen(target: widget.target))),
                    ),
                    // They said it builds their future, so the honest
                    // exit gets a real button — not just the back arrow.
                    // The app shows the cost; it never makes the call.
                    if (widget.forGrowth) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Kept. Bought with a clear head beats '
                                'bought on impulse.',
                              ),
                            ),
                          );
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                        child: const Text(
                          'Keep it — I decided with a clear head',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The assumptions behind the one quiet projection line: which market,
/// how long, and the disclosure in full.
class _AssumptionsSheet extends StatelessWidget {
  const _AssumptionsSheet({
    required this.funds,
    required this.asOf,
    required this.years,
    required this.fundIndex,
    required this.onYears,
    required this.onFund,
  });

  final List<FundSeries> funds;
  final String? asOf;
  final int years;
  final int fundIndex;
  final ValueChanged<int> onYears;
  final ValueChanged<int> onFund;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fund = fundIndex < funds.length ? funds[fundIndex] : null;
    final rate = fund?.fullHistoryCagr ?? kDefaultAnnualRate;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.paperHigh,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.cardShadow(opacity: 0.16),
          ),
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('About this projection', style: theme.textTheme.titleLarge),
              const SizedBox(height: 18),
              if (funds.isNotEmpty) ...[
                const SectionLabel('Market'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < funds.length; i++)
                      ChoiceChip(
                        label: Text(funds[i].name),
                        selected: i == fundIndex,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: i == fundIndex
                              ? AppColors.accent
                              : AppColors.textMid,
                        ),
                        onSelected: (_) => onFund(i),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              Row(
                children: [
                  const SectionLabel('Horizon'),
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
                max: ShockCard.maxYears.toDouble(),
                divisions: ShockCard.maxYears - 1,
                label: '$years y',
                onChanged: (v) => onYears(v.round()),
              ),
              const SizedBox(height: 6),
              Text(
                fund != null
                    ? 'Assumes ${fund.name} (${fund.ticker}) repeats its real '
                          '${fund.yearsAvailable}-year average total return of '
                          '${(rate * 100).toStringAsFixed(1)}%/yr, dividends '
                          'included'
                          '${asOf != null ? ', data to $asOf' : ''}. '
                          'Past performance doesn\'t guarantee future results. '
                          'Not investment advice.'
                    : 'Assumes ${(rate * 100).toStringAsFixed(0)}% average '
                          'annual return (historical market average). Not a '
                          'guarantee or investment advice.',
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

/// The user's own interview answer from the last time this urge came.
class _LastTimeCard extends StatelessWidget {
  const _LastTimeCard({required this.qa});

  final ReflectionQA qa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.washPeach.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last time, asked "${qa.question}", you said:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '"${qa.answer}"',
            style: theme.textTheme.titleMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

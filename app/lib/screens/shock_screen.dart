import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reflection.dart';
import '../models/burn_target.dart';
import '../providers/db_providers.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/math_utils.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/ember_ui.dart';
import '../widgets/shock_card.dart';
import 'burn_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketDataProvider).value;
    final funds = ref.watch(relevantFundsProvider);

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
                          child: ShockCard(
                            target: widget.target,
                            years: _years,
                            onYearsChanged: (y) => setState(() => _years = y),
                            funds: funds,
                            asOf: market?.asOfLabel,
                            fundIndex: _fund,
                            onFundChanged: (f) => setState(() => _fund = f),
                          ),
                        ),
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

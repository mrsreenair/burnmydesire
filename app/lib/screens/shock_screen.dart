import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                            market: market,
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
                child: EmberButton(
                  label: 'Burn this desire',
                  icon: Icons.local_fire_department,
                  kind: PillKind.fire,
                  onPressed: () => Navigator.of(
                    context,
                  ).push(fireRoute(BurnScreen(target: widget.target))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/burn_target.dart';
import '../providers/db_providers.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
import '../utils/motivation.dart';
import '../widgets/confetti.dart';
import '../widgets/ember_ui.dart';
import '../widgets/paper_backdrop.dart';

/// The payoff. Structured like a proper achievement screen: hero, earned
/// badge, one big headline, supporting line, pinned CTA — with a confetti
/// pop on arrival so the win registers before you read a word.
class VictoryScreen extends ConsumerStatefulWidget {
  const VictoryScreen({super.key, required this.target});

  final BurnTarget target;

  @override
  ConsumerState<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends ConsumerState<VictoryScreen> {
  @override
  void initState() {
    super.initState();
    _persistBurn();
    _celebrate();
  }

  /// A double beat under the confetti — the physical half of the reward.
  Future<void> _celebrate() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 110));
    await HapticFeedback.lightImpact();
  }

  Future<void> _persistBurn() async {
    final db = ref.read(databaseProvider);
    final target = widget.target;
    if (target.itemId != null) {
      await db.recordReBurn(target.itemId!);
    } else {
      final file = await ref.read(imageStoreProvider).save(target.imageBytes);
      await db.insertBurnedItem(
        imageFile: file,
        priceCents: target.priceCents,
        monthlyCents: target.plan?.monthlyCents,
        months: target.plan?.months,
        category: target.category,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = widget.target;
    final price = target.priceCents;
    final fund = ref.watch(marketDataProvider).value?.funds.first;
    final future = fund?.projectedValueCents(price, kDefaultHorizonYears) ??
        futureValueCents(price, years: kDefaultHorizonYears);
    final again = target.burnNumber > 1;

    final String badge;
    if (again) {
      badge = 'Resisted ${target.burnNumber}×';
    } else {
      badge = target.isEmotion ? 'Thought burned' : 'Desire destroyed';
    }

    return Scaffold(
      body: PaperBackdrop(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 24),
                          const PopIn(child: _HeroMark()),
                          const SizedBox(height: 28),
                          PopIn(
                            delay: const Duration(milliseconds: 260),
                            from: 0.8,
                            child: BadgePill(
                              badge,
                              color: target.isEmotion
                                  ? AppColors.accent
                                  : AppColors.money,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Reveal(
                            delay: const Duration(milliseconds: 340),
                            child: target.isEmotion
                                ? _ThoughtResult(target: target)
                                : _MoneyResult(
                                    target: target,
                                    price: price,
                                    future: future,
                                  ),
                          ),
                          if (!target.isEmotion && !again) ...[
                            const SizedBox(height: 20),
                            Reveal(
                              delay: const Duration(milliseconds: 520),
                              child: Text(
                                'Put it to work: a low-cost ETF at your '
                                'broker beats a gadget in a drawer.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textLow),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Withings-style pinned footer: hairline, then the pill.
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: AppColors.hairline)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Reveal(
                      delay: const Duration(milliseconds: 600),
                      offset: 12,
                      child: EmberButton(
                        label: 'Back to home',
                        onPressed: () =>
                            Navigator.of(context).popUntil((r) => r.isFirst),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const ConfettiBurst(),
          ],
        ),
      ),
    );
  }
}

/// The illustration slot: the flame resting in a soft disc, the way an
/// achievement mark sits on these screens.
class _HeroMark extends StatelessWidget {
  const _HeroMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.washPeach.withValues(alpha: 0.9),
            AppColors.washPeach.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: const Text('🔥', style: TextStyle(fontSize: 60)),
    );
  }
}

/// The money payoff: the protected amount is the headline, counting up.
class _MoneyResult extends StatelessWidget {
  const _MoneyResult({
    required this.target,
    required this.price,
    required this.future,
  });

  final BurnTarget target;
  final int price;
  final int future;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final again = target.burnNumber > 1;
    return Column(
      children: [
        Text(
          again ? 'Still protected' : 'You just protected',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        ShaderMask(
          shaderCallback: (b) => AppColors.wealthGradient.createShader(b),
          blendMode: BlendMode.srcIn,
          child: CountUpText(
            price,
            formatter: formatEuros,
            duration: const Duration(milliseconds: 1400),
            style: theme.textTheme.displayMedium,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          again
              ? 'This one keeps trying. You keep winning.'
              : 'Invested, that\'s ${formatEuros(future)} '
                  'in $kDefaultHorizonYears years.',
          textAlign: TextAlign.center,
          style:
              theme.textTheme.titleMedium?.copyWith(color: AppColors.textMid),
        ),
      ],
    );
  }
}

/// Thoughts have no price — the headline is the closure, the body is the
/// encouragement.
class _ThoughtResult extends StatelessWidget {
  const _ThoughtResult({required this.target});

  final BurnTarget target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          target.burnNumber > 1 ? 'Burned it again' : 'It\'s ash now',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        Text(
          motivationMessage(
            resistanceCount: target.burnNumber,
            seed: target.itemId ?? target.imageBytes.length,
          ),
          textAlign: TextAlign.center,
          style:
              theme.textTheme.titleMedium?.copyWith(color: AppColors.textMid),
        ),
      ],
    );
  }
}

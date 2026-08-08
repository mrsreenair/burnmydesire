import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/burn_target.dart';
import '../providers/db_providers.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
import '../utils/motivation.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/ember_ui.dart';

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

    final String headline;
    final String? footnote;
    if (target.isEmotion) {
      headline = target.burnNumber > 1 ? 'Burned it again' : 'Thought burned';
      footnote = null;
    } else {
      headline = 'Desire destroyed';
      footnote = 'Put it to work: a low-cost ETF at your broker beats a '
          'gadget in a drawer.';
    }

    return Scaffold(
      body: PaperBackdrop(
        // The fire just died down — back to warm daylight.
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Reveal(
                  duration: Motion.reveal,
                  offset: 12,
                  child: Breathe(
                    child: Text('🔥',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 72)),
                  ),
                ),
                const SizedBox(height: 20),
                Reveal(
                  delay: const Duration(milliseconds: 120),
                  child: Text(headline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium),
                ),
                const SizedBox(height: 28),
                Reveal(
                  delay: const Duration(milliseconds: 260),
                  child: target.isEmotion
                      ? Text(
                          motivationMessage(
                            resistanceCount: target.burnNumber,
                            seed: target.itemId ?? target.imageBytes.length,
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: AppColors.textMid),
                        )
                      : _MoneyResult(
                          target: target,
                          price: price,
                          future: future,
                        ),
                ),
                if (footnote != null) ...[
                  const SizedBox(height: 20),
                  Reveal(
                    delay: const Duration(milliseconds: 420),
                    child: Text(
                      footnote,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textLow),
                    ),
                  ),
                ],
                const Spacer(),
                Reveal(
                  delay: const Duration(milliseconds: 500),
                  child: EmberButton(
                    label: 'Done',
                    glow: false,
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The money payoff: protected amount counts up in mint, projection below.
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
    final reBurn = target.itemId != null;
    return Column(
      children: [
        Text(
          reBurn ? 'You resisted it again.' : 'You just protected',
          textAlign: TextAlign.center,
          style:
              theme.textTheme.titleMedium?.copyWith(color: AppColors.textMid),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (b) => AppColors.wealthGradient.createShader(b),
          blendMode: BlendMode.srcIn,
          child: CountUpText(
            price,
            formatter: formatEuros,
            duration: const Duration(milliseconds: 1200),
            style: theme.textTheme.displaySmall,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          reBurn
              ? '${formatEuros(price)} stays protected.'
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

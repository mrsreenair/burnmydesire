import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/burn_target.dart';
import '../providers/db_providers.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
import '../utils/motivation.dart';

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
    final String message;
    final String? footnote;
    if (target.isEmotion) {
      headline = target.burnNumber > 1 ? 'Burned it again' : 'Thought burned';
      message = motivationMessage(
        resistanceCount: target.burnNumber,
        seed: target.itemId ?? target.imageBytes.length,
      );
      footnote = null;
    } else {
      headline = 'Desire destroyed';
      message = target.itemId != null
          ? 'You resisted it again.\n${formatEuros(price)} stays protected.'
          : 'You just protected ${formatEuros(price)}.\n'
              'Invested, that\'s ${formatEuros(future)} '
              'in $kDefaultHorizonYears years.';
      footnote = 'Put it to work: a low-cost ETF at your broker beats a '
          'gadget in a drawer.';
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text('🔥', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text(headline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              if (footnote != null) ...[
                const SizedBox(height: 16),
                Text(
                  footnote,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18)),
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

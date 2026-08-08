import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/burn_target.dart';
import '../providers/db_providers.dart';
import '../utils/math_utils.dart';
import '../widgets/shock_card.dart';
import 'burn_screen.dart';

class ShockScreen extends ConsumerStatefulWidget {
  const ShockScreen({super.key, required this.target});

  final BurnTarget target;

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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: ShockCard(
                    target: widget.target,
                    years: _years,
                    onYearsChanged: (y) => setState(() => _years = y),
                    market: market,
                    fundIndex: _fund,
                    onFundChanged: (f) => setState(() => _fund = f),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18)),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BurnScreen(target: widget.target),
                ),
              ),
              icon: const Icon(Icons.local_fire_department),
              label: const Text('Burn this desire'),
            ),
          ],
        ),
      ),
    );
  }
}

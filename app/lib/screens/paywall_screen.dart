import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config.dart';
import '../providers/pro_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Offerings? _offerings;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (kRevenueCatIosApiKey.isNotEmpty) {
      Purchases.getOfferings().then((o) {
        if (mounted) setState(() => _offerings = o);
      }).ignore();
    }
  }

  Future<void> _buy(Package package) async {
    setState(() => _busy = true);
    try {
      await Purchases.purchase(PurchaseParams.package(package));
      if (mounted && ref.read(proProvider)) Navigator.of(context).pop();
    } on Exception {
      // User cancelled or store error — stay on the paywall.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await Purchases.restorePurchases();
      if (mounted && ref.read(proProvider)) Navigator.of(context).pop();
    } on Exception {
      // Nothing to restore.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configured = ref.watch(purchasesConfiguredProvider);
    final packages = _offerings?.current?.availablePackages ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Go Pro')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Burn without limits',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            const _Feature('♾️', 'Unlimited temptations'),
            const _Feature('📈', 'Custom return rates & horizons'),
            const _Feature('📊', 'Wealth-protected analytics'),
            const _Feature('🔥', 'Every future destruction effect'),
            const SizedBox(height: 24),
            if (!configured)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Purchases aren\'t live in this build yet.\n'
                    'Pro: €2.99/month · €19.99/year · €29.99 lifetime.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else if (packages.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              for (final p in packages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _busy ? null : () => _buy(p),
                    child: Text(
                        '${p.storeProduct.title} — ${p.storeProduct.priceString}'),
                  ),
                ),
            const Spacer(),
            if (configured)
              TextButton(
                onPressed: _busy ? null : _restore,
                child: const Text('Restore purchases'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.emoji, this.label);

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

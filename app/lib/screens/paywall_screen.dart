import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config.dart';
import '../providers/pro_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/ember_ui.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.embedded = false, this.headline});

  /// True when shown as a tab: no close button, and room for the tab bar.
  final bool embedded;

  /// Contextual opener ("You let go of 5 desires this month.") shown
  /// instead of the generic one when the paywall was reached by hitting
  /// a limit — the moment should acknowledge the win, not scold.
  final String? headline;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Offerings? _offerings;
  bool _busy = false;
  int _picked = 0;

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
      appBar: widget.embedded
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
      extendBodyBehindAppBar: !widget.embedded,
      body: PaperBackdrop(
        child: SafeArea(
          bottom: !widget.embedded,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, widget.embedded ? 96 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Reveal(
                  child: Breathe(
                    child: Text(
                      '🔥',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 56),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Reveal(
                  delay: const Duration(milliseconds: 80),
                  child: GradientText(
                    widget.headline ?? 'Burn without limits',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 24),
                for (final (i, f) in const [
                  ('♾️', 'Unlimited desires, every month'),
                  ('📈', 'Custom return rates & horizons'),
                  ('📊', 'Wealth-protected analytics'),
                  ('🔥', 'Every future destruction effect'),
                ].indexed)
                  Reveal(
                    delay: Duration(milliseconds: 160 + 70 * i),
                    offset: 14,
                    child: _Feature(f.$1, f.$2),
                  ),
                const Spacer(),
                if (!configured)
                  Reveal(
                    delay: const Duration(milliseconds: 440),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.paperHigh,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.cardShadow(opacity: 0.06),
                      ),
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
                else ...[
                  for (final (i, p) in packages.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PlanCard(
                        title: p.storeProduct.title,
                        price: p.storeProduct.priceString,
                        selected: i == _picked,
                        onTap: () => setState(() => _picked = i),
                      ),
                    ),
                  const SizedBox(height: 6),
                  EmberButton(
                    label: 'Continue',
                    onPressed: _busy ? null : () => _buy(packages[_picked]),
                  ),
                ],
                if (configured)
                  TextButton(
                    onPressed: _busy ? null : _restore,
                    child: const Text('Restore purchases'),
                  ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.ember.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.paperHigh,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : AppColors.ink.withValues(alpha: 0.06),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected ? null : AppColors.cardShadow(opacity: 0.05),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              price,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.accent : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

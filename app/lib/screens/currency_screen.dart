import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/currencies.dart';
import '../providers/currency_provider.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/ember_ui.dart';
import '../widgets/paper_backdrop.dart';
import 'goal_selection_screen.dart';

/// One question with the answer already filled in: the device locale's
/// currency arrives pre-selected, so for almost everyone this screen is
/// a single glance and one tap of Continue — not a form.
class CurrencyScreen extends ConsumerStatefulWidget {
  const CurrencyScreen({super.key});

  @override
  ConsumerState<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends ConsumerState<CurrencyScreen> {
  late Currency _selected = detectCurrency();

  Future<void> _finish() async {
    await ref.read(currencyProvider.notifier).change(_selected);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(emberRoute(const GoalSelectionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Detected first, the rest in launch-market order.
    final ordered = [
      _selected,
      for (final c in currencies)
        if (c.code != _selected.code) c,
    ];
    return Scaffold(
      body: PaperBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Reveal(
                  child: Text(
                    'Your money',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Reveal(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    'Prices and savings will be shown in this currency.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Reveal(
                    delay: const Duration(milliseconds: 140),
                    child: ListView.separated(
                      itemCount: ordered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final c = ordered[i];
                        final on = c.code == _selected.code;
                        return CurrencyTile(
                          currency: c,
                          selected: on,
                          onTap: () => setState(() => _selected = c),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                EmberButton(
                  label: 'Continue with ${_selected.code}',
                  onPressed: _finish,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One currency row, shared with the Settings picker.
class CurrencyTile extends StatelessWidget {
  const CurrencyTile({
    super.key,
    required this.currency,
    required this.selected,
    required this.onTap,
  });

  final Currency currency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.10)
          : AppColors.paperHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.hairline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(currency.flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currency.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${currency.symbol.trim()} ${currency.code}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? AppColors.accent : AppColors.textMid,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

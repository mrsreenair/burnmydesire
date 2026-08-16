import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/burn_target.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
import '../utils/subscription_image.dart';
import '../widgets/ember_ui.dart';
import '../widgets/paper_backdrop.dart';
import 'shock_screen.dart';

/// Capture a subscription.
///
/// The biggest leak in most people's money isn't the €400 thing they
/// photograph — it's €11.99 a month, eleven times over, that never feels
/// like a decision because it was only decided once. This is the capture
/// flow for that: a name, an amount, how often, and no camera, because a
/// subscription has nothing to photograph.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  BillingPeriod _period = BillingPeriod.monthly;
  bool _busy = false;

  int? get _cents => parseMoneyToCents(_amount.text);

  String? get _blocker {
    if (_name.text.trim().isEmpty && _cents == null) {
      return 'Name it, and say what it takes';
    }
    if (_name.text.trim().isEmpty) return 'What is it called?';
    if (_cents == null) return 'What does it take each time?';
    return null;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final cents = _cents;
    if (cents == null || _busy) return;
    setState(() => _busy = true);

    final bytes = await renderSubscriptionImage(
      name: _name.text.trim(),
      amountLabel: formatMoney(cents),
      period: _period,
    );
    final image = await decodeImageFromList(bytes);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      emberRoute(
        ShockScreen(
          target: BurnTarget(
            image: image,
            imageBytes: bytes,
            // A year is what goes in the ledger. Counting a cancelled
            // subscription's whole future would let one tap add thousands
            // to the protected total and make every other number in the
            // app worthless.
            priceCents: yearlyCostCents(cents, _period),
            category: 'subscription',
            recurringCents: cents,
            billingPeriod: _period,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocker = _blocker;
    final cents = _cents;
    final symbol = activeCurrency.symbol.trim();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: PaperBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            children: [
              Reveal(
                child: Text(
                  'What keeps\ncharging you?',
                  style: theme.textTheme.displaySmall,
                ),
              ),
              const SizedBox(height: 8),
              Reveal(
                delay: const Duration(milliseconds: 40),
                child: Text(
                  'The subscription you meant to cancel. Small enough to '
                  'ignore, forever is a long time.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textMid,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Reveal(
                delay: const Duration(milliseconds: 80),
                child: const SectionLabel('The subscription'),
              ),
              const SizedBox(height: 10),
              Reveal(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.paperHigh,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppColors.cardShadow(opacity: 0.06),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          style: theme.textTheme.titleLarge,
                          decoration: InputDecoration(
                            filled: false,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'e.g. that streaming service',
                            hintStyle: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.textLow.withValues(alpha: 0.6),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.hairline),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              symbol,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textLow,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _amount,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: theme.textTheme.displaySmall,
                                decoration: InputDecoration(
                                  filled: false,
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: theme.textTheme.displaySmall
                                      ?.copyWith(
                                        color: AppColors.textLow.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Row(
                          children: [
                            for (final p in BillingPeriod.values) ...[
                              ChoiceChip(
                                label: Text(switch (p) {
                                  BillingPeriod.weekly => 'a week',
                                  BillingPeriod.monthly => 'a month',
                                  BillingPeriod.yearly => 'a year',
                                }),
                                selected: p == _period,
                                showCheckmark: false,
                                onSelected: (_) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _period = p);
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // The number nobody does in their head. Shown the moment
              // there's an amount, because it IS the argument.
              if (cents != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.flame.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'That\'s ${formatMoney(yearlyCostCents(cents, _period))} '
                    'a year — every year, until you cancel.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),
              if (blocker != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    blocker,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                ),
              EmberButton(
                label: 'Show me the damage',
                icon: Icons.bolt,
                onPressed: blocker == null && !_busy ? _continue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

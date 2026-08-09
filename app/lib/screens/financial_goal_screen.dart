import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/financial_goal.dart';
import '../providers/financial_goal_provider.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/format_utils.dart';
import '../widgets/burn_chip.dart';
import '../widgets/ember_ui.dart';
import '../widgets/paper_backdrop.dart';
import 'disclaimer_screen.dart';

/// "What are you saving for?" — the destination every burn moves toward.
///
/// Deliberately skippable in setup: a goal invented under pressure is a
/// goal nobody feels. The presets carry no prices — a car costs a very
/// different number in Mumbai and in Munich, so the amount is always the
/// user's own.
class FinancialGoalScreen extends ConsumerStatefulWidget {
  const FinancialGoalScreen({super.key, this.inSetup = true});

  /// In setup the screen flows on to the disclaimer; from Settings it
  /// just pops back.
  final bool inSetup;

  @override
  ConsumerState<FinancialGoalScreen> createState() =>
      _FinancialGoalScreenState();
}

class _FinancialGoalScreenState extends ConsumerState<FinancialGoalScreen> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  String _emoji = '🌱';

  @override
  void initState() {
    super.initState();
    // Editing an existing goal starts from it.
    savedFinancialGoal().then((g) {
      if (g == null || !mounted) return;
      setState(() {
        _name.text = g.name;
        _amount.text = (g.targetCents ~/ 100).toString();
        _emoji = g.emoji;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _pickPreset(String name, String emoji) {
    setState(() {
      _name.text = name;
      _emoji = emoji;
    });
  }

  int? get _targetCents => parseMoneyToCents(_amount.text);

  bool get _ready => _name.text.trim().isNotEmpty && _targetCents != null;

  void _leave() {
    if (widget.inSetup) {
      Navigator.of(context).pushReplacement(
        emberRoute(const DisclaimerScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    await saveFinancialGoal(
      FinancialGoal(
        name: _name.text.trim(),
        emoji: _emoji,
        targetCents: _targetCents!,
      ),
    );
    ref.invalidate(financialGoalProvider);
    if (mounted) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = _targetCents;
    return Scaffold(
      appBar: widget.inSetup ? null : AppBar(title: const Text('Your goal')),
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
                    'What are you saving for?',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Reveal(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    'Every burn moves you toward it. You can change '
                    'this any time.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final (i, (name, emoji))
                                in goalPresets.indexed)
                              Reveal(
                                delay: Duration(milliseconds: 120 + 40 * i),
                                offset: 14,
                                child: BurnChip(
                                  emoji: emoji,
                                  label: name,
                                  selected: _name.text == name,
                                  onChanged: (_) => _pickPreset(name, emoji),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Reveal(
                          delay: const Duration(milliseconds: 200),
                          child: TextField(
                            controller: _name,
                            textCapitalization:
                                TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Your goal, in your words',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Reveal(
                          delay: const Duration(milliseconds: 240),
                          child: TextField(
                            controller: _amount,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'What it costs',
                              prefixText:
                                  '${activeCurrency.symbol.trim()} ',
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (target != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            '$_emoji ${_name.text.trim()} — '
                            '${formatMoney(target)}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.textMid,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                EmberButton(
                  label: _ready ? 'Set my goal' : 'Pick a goal and a price',
                  onPressed: _ready ? _save : null,
                ),
                if (widget.inSetup)
                  TextButton(
                    onPressed: _leave,
                    child: const Text('Maybe later'),
                  )
                else
                  TextButton(
                    onPressed: () async {
                      await clearFinancialGoal();
                      ref.invalidate(financialGoalProvider);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Remove goal'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

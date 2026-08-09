import 'package:flutter/material.dart';

import '../data/user_prefs.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/burn_chip.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/ember_ui.dart';
import 'disclaimer_screen.dart';

/// Pick the spending temptations that hit hardest. Feeds dashboard
/// personalization later; stored on-device only.
class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final _selected = <String>{};

  Future<void> _finish() async {
    await saveSpendCategories(_selected.toList());
    if (!mounted) return;
    Navigator.of(context).pushReplacement(emberRoute(const DisclaimerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    'Where does your money leak?',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Reveal(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    'Pick everything you can\'t resist. '
                    'We\'ll help you burn it.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final (i, (label, emoji))
                            in spendCategories.indexed)
                          Reveal(
                            delay: Duration(milliseconds: 120 + 40 * i),
                            offset: 14,
                            child: BurnChip(
                              emoji: emoji,
                              label: label,
                              selected: _selected.contains(label),
                              onChanged: (on) => setState(
                                () => on
                                    ? _selected.add(label)
                                    : _selected.remove(label),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                EmberButton(
                  label: _selected.isEmpty
                      ? 'Pick at least one'
                      : 'Continue (${_selected.length} selected)',
                  onPressed: _selected.isEmpty ? null : _finish,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

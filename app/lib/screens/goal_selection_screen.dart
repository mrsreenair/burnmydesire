import 'package:flutter/material.dart';

import '../data/user_prefs.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/burn_chip.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/ember_ui.dart';
import 'category_selection_screen.dart';
import 'disclaimer_screen.dart';

/// "What do you want to burn?" — the goals that shape the whole app.
/// Stored on-device only; this is health-grade private data.
class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  final _selected = <String>{};

  Future<void> _finish() async {
    await saveBurnGoals(_selected.toList());
    if (!mounted) return;
    // Impulse buyers also pick their spending weak spots; everyone else
    // goes straight to the disclaimer.
    final next = _selected.contains('impulse_buying')
        ? const CategorySelectionScreen()
        : const DisclaimerScreen();
    Navigator.of(context).pushReplacement(emberRoute(next));
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
                  child: Text('What do you want to burn?',
                      style: theme.textTheme.headlineMedium),
                ),
                const SizedBox(height: 8),
                Reveal(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                      'Pick every desire that owns you. '
                      'This never leaves your phone.',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: AppColors.textMid)),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final (i, (id, label, emoji))
                            in burnGoals.indexed)
                          Reveal(
                            delay: Duration(milliseconds: 120 + 40 * i),
                            offset: 14,
                            child: BurnChip(
                              emoji: emoji,
                              label: label,
                              selected: _selected.contains(id),
                              onChanged: (on) => setState(() =>
                                  on ? _selected.add(id) : _selected.remove(id)),
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

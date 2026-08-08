import 'package:flutter/material.dart';

import '../data/user_prefs.dart';
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text('What do you want to burn?',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                  'Pick every desire that owns you. '
                  'This never leaves your phone.',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final (id, label, emoji) in burnGoals)
                        FilterChip(
                          label: Text('$emoji  $label'),
                          labelStyle: theme.textTheme.titleMedium,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          selected: _selected.contains(id),
                          onSelected: (on) => setState(
                              () => on ? _selected.add(id) : _selected.remove(id)),
                        ),
                    ],
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    minimumSize: const Size.fromHeight(56)),
                onPressed: _selected.isEmpty ? null : _finish,
                child: Text(_selected.isEmpty
                    ? 'Pick at least one'
                    : 'Continue (${_selected.length} selected)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

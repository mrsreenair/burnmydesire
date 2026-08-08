import 'package:flutter/material.dart';

import '../data/user_prefs.dart';
import 'home_screen.dart';

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
    await markSetupComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
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
              Text('Where does your money leak?',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Pick everything you can\'t resist. We\'ll help you burn it.',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final (label, emoji) in spendCategories)
                        FilterChip(
                          label: Text('$emoji  $label'),
                          labelStyle: theme.textTheme.titleMedium,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          selected: _selected.contains(label),
                          onSelected: (on) => setState(() =>
                              on ? _selected.add(label) : _selected.remove(label)),
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

import 'package:flutter/material.dart';

import '../data/user_prefs.dart';
import 'home_screen.dart';

/// Last onboarding step: an honest, caring note about what this app is
/// and isn't. Completing it marks setup done.
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  Future<void> _finish(BuildContext context) async {
    await markSetupComplete();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.titleMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text('🤍',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text('One honest thing first',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Text(
                'This app is a ritual, not a treatment. It helps you pause, '
                'see clearly, and let go — one urge at a time.',
                textAlign: TextAlign.center,
                style: muted,
              ),
              const SizedBox(height: 16),
              Text(
                'If an addiction is hurting your health, relationships, or '
                'life, talking to a doctor or therapist is a power move — '
                'not a defeat. Use this app alongside real support, never '
                'instead of it.',
                textAlign: TextAlign.center,
                style: muted,
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    minimumSize: const Size.fromHeight(56)),
                onPressed: () => _finish(context),
                child: const Text('I understand'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

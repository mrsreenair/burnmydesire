import 'package:flutter/material.dart';

import '../data/user_prefs.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/ember_ui.dart';
import 'root_shell.dart';

/// Last onboarding step: an honest, caring note about what this app is
/// and isn't. Completing it marks setup done.
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  Future<void> _finish(BuildContext context) async {
    await markSetupComplete();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      emberRoute(const RootShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.titleMedium
        ?.copyWith(color: AppColors.textMid, height: 1.5);
    return Scaffold(
      body: PaperBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Reveal(
                  child: Text('🤍',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 24),
                Reveal(
                  delay: const Duration(milliseconds: 90),
                  child: Text('One honest thing first',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium),
                ),
                const SizedBox(height: 16),
                Reveal(
                  delay: const Duration(milliseconds: 180),
                  child: Text(
                    'This app is a ritual, not a treatment. It helps you '
                    'pause, see clearly, and let go — one urge at a time.',
                    textAlign: TextAlign.center,
                    style: muted,
                  ),
                ),
                const SizedBox(height: 16),
                Reveal(
                  delay: const Duration(milliseconds: 270),
                  child: Text(
                    'If an addiction is hurting your health, relationships, '
                    'or life, talking to a doctor or therapist is a power '
                    'move — not a defeat. Use this app alongside real '
                    'support, never instead of it.',
                    textAlign: TextAlign.center,
                    style: muted,
                  ),
                ),
                const Spacer(),
                Reveal(
                  delay: const Duration(milliseconds: 360),
                  child: EmberButton(
                    label: 'I understand',
                    glow: false,
                    onPressed: () => _finish(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

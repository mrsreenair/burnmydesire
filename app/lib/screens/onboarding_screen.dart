import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/ember_ui.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/tilt_card.dart';
import 'disclaimer_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      ['🛍️', '🔥', '💶'],
      'Craving something?',
      'Impulse buys aren\'t a math problem — they\'re a dopamine loop. '
          'Burn My Desire breaks it in two punches.',
    ),
    (
      ['💸', '📈', '⏳'],
      'See the real damage',
      'Every purchase steals from your future self. We show you exactly '
          'how much wealth that gadget really costs over 10, 20, 30 years.',
    ),
    (
      ['📷', '🔥', '🕯️'],
      'Then burn it',
      'Photograph what you crave and set it on fire. Watch it turn to ash. '
          'The craving goes with it — and your money stays yours.',
    ),
  ];

  void _finish() {
    // Straight to the duty-of-care note, then the app. Everything else —
    // name, PIN, currency, goals — is asked *after* the first burn.
    //
    // The old flow put seven screens between install and the thing the
    // app is for. None of them are needed to burn something: the currency
    // is already guessed from the locale, and a PIN protects data that
    // doesn't exist yet. Activation is the metric this funnel was
    // costing (PROJECT.md §11).
    //
    // The disclaimer stays in front. It's the one screen that isn't
    // setup — it's what we owe someone before they use this on an
    // addiction — and it's short.
    Navigator.of(context).pushReplacement(emberRoute(const DisclaimerScreen()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _page == _pages.length - 1;

    return Scaffold(
      body: PaperBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final (emojis, title, body) = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Reveal(
                            key: ValueKey('fan$i-${_page == i}'),
                            duration: Motion.reveal,
                            offset: 16,
                            child: CardFan(
                              size: 84,
                              cards: [
                                for (final e in emojis)
                                  Text(e, style: const TextStyle(fontSize: 30)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Reveal(
                            key: ValueKey('title$i-${_page == i}'),
                            delay: const Duration(milliseconds: 90),
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Reveal(
                            key: ValueKey('body$i-${_page == i}'),
                            delay: const Duration(milliseconds: 180),
                            child: Text(
                              body,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.textMid,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Active dot stretches into a pill; inactive dots stay dots.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: Motion.base,
                      curve: Motion.easeOut,
                      width: i == _page ? 28 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _page
                            ? AppColors.accent
                            : AppColors.textLow.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: EmberButton(
                    label: last ? 'Start burning' : 'Next',
                    icon: last ? Icons.local_fire_department : null,
                    kind: last ? PillKind.fire : PillKind.ink,
                    onPressed: last
                        ? _finish
                        : () => _controller.nextPage(
                            duration: Motion.base,
                            curve: Motion.easeOut,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

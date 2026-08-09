import 'package:flutter/material.dart';

import '../models/burn_target.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/burnable_image.dart';
import 'victory_screen.dart';

/// The ritual. Pure black room; as the user holds, the fire's glow
/// spreads across the screen and the hint text burns away.
class BurnScreen extends StatefulWidget {
  const BurnScreen({super.key, required this.target});

  final BurnTarget target;

  @override
  State<BurnScreen> createState() => _BurnScreenState();
}

class _BurnScreenState extends State<BurnScreen> {
  final _progress = ValueNotifier<double>(0);

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF060508),
      appBar: AppBar(backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: ValueListenableBuilder<double>(
        valueListenable: _progress,
        builder: (context, p, child) => Stack(
          fit: StackFit.expand,
          children: [
            // The room catches the firelight as the burn progresses.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    Color.lerp(
                      Colors.transparent,
                      AppColors.coal.withValues(alpha: 0.45),
                      Curves.easeIn.transform(p.clamp(0, 1)),
                    )!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            child!,
            // Hint burns away as soon as the user commits.
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: AnimatedOpacity(
                  duration: Motion.base,
                  opacity: p > 0.02 ? 0 : 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _HoldRing(),
                      const SizedBox(height: 14),
                      Text(
                        'Press and hold. Let it go.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // No padding and no clip: the sheet runs edge to edge, and the
        // flames need to spill past its bounds to read as fire.
        child: Center(
          child: BurnableImage(
            image: widget.target.image,
            onProgress: (p) => _progress.value = p,
            onBurned: () => Navigator.of(context).pushReplacement(
              fireRoute(VictoryScreen(target: widget.target)),
            ),
          ),
        ),
      ),
    );
  }
}

/// A slow-pulsing ember ring that marks the press-and-hold affordance.
class _HoldRing extends StatefulWidget {
  const _HoldRing();

  @override
  State<_HoldRing> createState() => _HoldRingState();
}

class _HoldRingState extends State<_HoldRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value);
        return SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Expanding, fading ripple.
              Container(
                width: 24 + 32 * t,
                height: 24 + 32 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        AppColors.ember.withValues(alpha: 0.5 * (1 - t)),
                    width: 1.5,
                  ),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.emberGradient,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

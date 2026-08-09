import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/burn_target.dart';
import '../providers/burn_effect_provider.dart';
import '../theme/motion.dart';
import '../widgets/burnable_image.dart';
import '../widgets/hold_to_burn_button.dart';
import 'victory_screen.dart';

/// Space the Hold-to-burn control needs at the bottom: its own 72 margin,
/// its 58 height, and room to breathe above it.
const double _buttonZone = 150;

/// The ritual. Pure black room; as the user holds, the burn's glow
/// spreads across the screen and the hint text burns away.
class BurnScreen extends ConsumerStatefulWidget {
  const BurnScreen({super.key, required this.target});

  final BurnTarget target;

  @override
  ConsumerState<BurnScreen> createState() => _BurnScreenState();
}

class _BurnScreenState extends ConsumerState<BurnScreen> {
  final _progress = ValueNotifier<double>(0);
  final _hold = BurnHoldController();

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effect = ref.watch(burnEffectProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF060508),
      appBar: AppBar(backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: ValueListenableBuilder<double>(
        valueListenable: _progress,
        builder: (context, p, child) => Stack(
          fit: StackFit.expand,
          children: [
            // The room catches the burn's own light as it progresses —
            // orange for fire, near-nothing for ash, blue for cold.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    Color.lerp(
                      Colors.transparent,
                      effect.glow.withValues(alpha: 0.45),
                      Curves.easeIn.transform(p.clamp(0, 1)),
                    )!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            child!,
            // The commit control. Stays put while the paper burns so the
            // finger never loses its target.
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 72),
                child: AnimatedOpacity(
                  duration: Motion.base,
                  opacity: p > 0.995 ? 0 : 1,
                  child: HoldToBurnButton(
                    progress: _progress,
                    onHoldStart: _hold.press,
                    onHoldEnd: _hold.release,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Inset, not full-bleed: a sheet you can see all four edges of
        // reads as an object lying in the dark. Run it to the screen edge
        // and it stops being paper and becomes a background. Still no
        // clip — flames must spill past the sheet's bounds.
        //
        // The vertical insets reserve the app bar and the button so the
        // sheet centres in the space that's actually free; without them it
        // centres on the whole screen and the slack all piles up at the top.
        // Center matters too: it loosens the Stack's tight constraints,
        // which the paper's OverflowBox depends on to size itself.
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            MediaQuery.paddingOf(context).top + kToolbarHeight,
            18,
            _buttonZone,
          ),
          child: Center(
            child: BurnableImage(
              image: widget.target.image,
              shaderAsset: effect.asset,
              controller: _hold,
              onProgress: (p) => _progress.value = p,
              onBurned: () => Navigator.of(context).pushReplacement(
                fireRoute(VictoryScreen(target: widget.target)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

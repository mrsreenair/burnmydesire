import 'package:flutter/material.dart';

import '../models/burn_target.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/burnable_image.dart';
import '../widgets/hold_to_burn_button.dart';
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
  final _hold = BurnHoldController();

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // The commit control. Stays put while the paper burns so the
            // finger never loses its target.
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 44),
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
        // No padding and no clip: the sheet runs edge to edge, and the
        // flames need to spill past its bounds to read as fire.
        child: Center(
          child: BurnableImage(
            image: widget.target.image,
            controller: _hold,
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


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// The commit control for the ritual: a fire-gradient pill you hold.
///
/// No progress readout — the burning sheet above *is* the progress bar,
/// and a percentage competing with it just split the user's attention.
///
/// Deliberately a *hold*, not a tap. Destroying something should cost a
/// few seconds of deliberate pressure — the same reason Me+ and Opal gate
/// quitting behind a hold rather than a button you can hit by accident.
class HoldToBurnButton extends StatefulWidget {
  const HoldToBurnButton({
    super.key,
    required this.progress,
    required this.onHoldStart,
    required this.onHoldEnd,
    this.label = 'Hold to burn',
    this.holdingLabel = 'Keep holding…',
  });

  /// Burn progress 0→1, driven by whoever owns the animation.
  final ValueListenable<double> progress;

  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final String label;
  final String holdingLabel;

  @override
  State<HoldToBurnButton> createState() => _HoldToBurnButtonState();
}

class _HoldToBurnButtonState extends State<HoldToBurnButton> {
  bool _held = false;

  void _down() {
    setState(() => _held = true);
    widget.onHoldStart();
  }

  void _up() {
    if (!_held) return;
    setState(() => _held = false);
    widget.onHoldEnd();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.progress,
      builder: (context, p, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Listener(
              onPointerDown: (_) => _down(),
              onPointerUp: (_) => _up(),
              onPointerCancel: (_) => _up(),
              child: AnimatedScale(
                scale: _held ? 0.96 : 1.0,
                duration: Motion.fast,
                curve: Motion.easeOut,
                child: Container(
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.emberGradient,
                    borderRadius: BorderRadius.circular(29),
                    boxShadow: AppColors.emberGlow(
                      // The pill glows harder the closer the paper is to
                      // gone, so the button itself feels like it's heating.
                      opacity: 0.22 + 0.4 * p,
                      blur: 22 + 26 * p,
                    ),
                  ),
                  child: Text(
                    _held ? widget.holdingLabel : widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

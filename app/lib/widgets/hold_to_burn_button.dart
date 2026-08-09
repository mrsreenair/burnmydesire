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
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(29),
                    boxShadow: AppColors.emberGlow(
                      // The pill glows harder the closer the paper is to
                      // gone, so the button itself feels like it's heating.
                      opacity: 0.22 + 0.4 * p,
                      blur: 22 + 26 * p,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(29),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Unlit track: the fire the button hasn't reached.
                        const ColoredBox(color: Color(0xFF3A1206)),
                        // The progress itself, filling the button left to
                        // right. Putting it inside the control rather than
                        // in a separate ring keeps the eye in one place —
                        // the finger is already here.
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: p.clamp(0.0, 1.0),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.emberGradient,
                            ),
                          ),
                        ),
                        // Hot leading edge, so the boundary reads as fire
                        // eating along the pill instead of a flat bar.
                        if (p > 0.001 && p < 0.999)
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: p.clamp(0.0, 1.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 14,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.spark.withValues(alpha: 0),
                                      AppColors.spark,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Center(
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
                      ],
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

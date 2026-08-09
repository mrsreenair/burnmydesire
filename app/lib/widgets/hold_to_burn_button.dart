import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// The commit control for the ritual: a ring that fills as you hold, over
/// a fire-gradient pill.
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
            _ProgressRing(progress: p, active: _held),
            const SizedBox(height: 20),
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

/// Ring + percentage. At rest it breathes gently to read as "hold me";
/// under the finger it stops breathing and just fills.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.active});

  final double progress;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      // The paper now fills the screen, so the ring needs to carry its own
      // contrast — without this disc it vanishes against the cream page.
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.55),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(78),
            painter: _RingPainter(progress),
          ),
          AnimatedOpacity(
            duration: Motion.fast,
            opacity: progress > 0.004 ? 1 : 0,
            child: Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // Before the first touch, the centre shows a flame instead of 0%.
          AnimatedOpacity(
            duration: Motion.fast,
            opacity: progress > 0.004 ? 0 : 1,
            child: Icon(
              Icons.local_fire_department,
              size: 26,
              color: Colors.white.withValues(alpha: active ? 0.95 : 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final rect = Offset.zero & size;
    final centre = rect.center;
    final radius = (size.width - stroke) / 2;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.14),
    );

    if (progress <= 0.001) return;

    // Sweep starts at 12 o'clock and runs clockwise, coloured by the fire
    // gradient so the ring belongs to the same flame as everything else.
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: 0,
          endAngle: 2 * math.pi,
          colors: [AppColors.spark, AppColors.ember, AppColors.flame],
          transform: GradientRotation(start),
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A one-shot confetti pop: pieces burst outward from [origin], arc under
/// gravity, tumble as they fall, then fade out.
///
/// Purely painted — no images, no packages, one CustomPaint for the whole
/// field. Wrap it over content inside a Stack; it never eats taps.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.count = 68,
    this.duration = const Duration(milliseconds: 2800),
    this.origin = const Alignment(0, -0.28),
  });

  /// Number of pieces. Half render as squares, half as curled ribbons.
  final int count;

  final Duration duration;

  /// Where the pop comes from, in Alignment space (-1..1 on both axes).
  final Alignment origin;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)..forward();

  late final List<_Piece> _pieces = _buildPieces();

  /// Festive but on-brand: the fire accents plus cool counterpoints so the
  /// burst doesn't read as more flame.
  static const _palette = [
    AppColors.accent,
    AppColors.money,
    AppColors.sticky,
    Color(0xFF7A6BE0), // periwinkle
    Color(0xFF4FC9A6), // mint
    AppColors.flame,
  ];

  List<_Piece> _buildPieces() {
    // Fixed seed: the celebration looks the same every time, which makes it
    // feel authored rather than noisy.
    final rng = math.Random(11);
    return List.generate(widget.count, (i) {
      return _Piece(
        angle: rng.nextDouble() * math.pi * 2,
        // Wide speed spread so some pieces reach the edges and some stay
        // near the hero — that variance is what sells a real popper. Fast
        // enough that the headline is clear again within about a second.
        speed: 220 + rng.nextDouble() * 480,
        size: 7 + rng.nextDouble() * 8,
        spin: (rng.nextDouble() - 0.5) * 9,
        tilt: rng.nextDouble() * math.pi,
        drift: (rng.nextDouble() - 0.5) * 60,
        color: _palette[i % _palette.length],
        ribbon: i.isOdd,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              pieces: _pieces,
              t: _controller.value,
              seconds: widget.duration.inMilliseconds / 1000,
              origin: widget.origin,
            ),
          ),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.tilt,
    required this.drift,
    required this.color,
    required this.ribbon,
  });

  final double angle; // launch direction
  final double speed; // px/s
  final double size;
  final double spin; // rad/s
  final double tilt; // starting rotation
  final double drift; // sideways sway amplitude
  final Color color;
  final bool ribbon;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.pieces,
    required this.t,
    required this.seconds,
    required this.origin,
  });

  final List<_Piece> pieces;
  final double t; // 0→1 over the whole animation
  final double seconds;
  final Alignment origin;

  static const _gravity = 620.0; // px/s²

  @override
  void paint(Canvas canvas, Size size) {
    final start = origin.alongSize(size);
    final elapsed = t * seconds;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in pieces) {
      // Ballistic path: launch outward, gravity takes over, plus a little
      // sideways sway so pieces flutter instead of falling on rails.
      final dx = math.cos(p.angle) * p.speed * elapsed +
          math.sin(elapsed * 2.4 + p.tilt) * p.drift * elapsed;
      final dy = math.sin(p.angle) * p.speed * elapsed +
          0.5 * _gravity * elapsed * elapsed;

      // Snap in over the first beat, dissolve over the last third.
      final fadeIn = (t / 0.06).clamp(0.0, 1.0);
      final fadeOut = t < 0.62 ? 1.0 : (1 - (t - 0.62) / 0.38).clamp(0.0, 1.0);
      final alpha = fadeIn * fadeOut;
      if (alpha <= 0.01) continue;

      canvas.save();
      canvas.translate(start.dx + dx, start.dy + dy);
      canvas.rotate(p.tilt + p.spin * elapsed);
      paint.color = p.color.withValues(alpha: alpha);

      if (p.ribbon) {
        // A curled streamer: short arc, round caps.
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = p.size * 0.34
          ..strokeCap = StrokeCap.round;
        final w = p.size * 1.7;
        canvas.drawPath(
          Path()
            ..moveTo(-w, 0)
            ..quadraticBezierTo(0, -w * 0.9, w, 0),
          paint,
        );
        paint.style = PaintingStyle.fill;
      } else {
        // Foil square, squashed on one axis to fake tumbling in 3D.
        final squash = math.cos(p.spin * elapsed).abs().clamp(0.25, 1.0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * squash,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

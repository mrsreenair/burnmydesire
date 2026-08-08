import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// The burn ritual: press-and-hold dissolves [image] through the GLSL
/// shader with haptic ticks; [onBurned] fires once when fully burned.
class BurnableImage extends StatefulWidget {
  const BurnableImage({
    super.key,
    required this.image,
    required this.onBurned,
    this.duration = const Duration(milliseconds: 3000),
  });

  final ui.Image image;
  final VoidCallback onBurned;
  final Duration duration;

  @override
  State<BurnableImage> createState() => _BurnableImageState();
}

class _BurnableImageState extends State<BurnableImage>
    with TickerProviderStateMixin {
  static Future<ui.FragmentProgram>? _programFuture;

  ui.FragmentProgram? _program;
  late final AnimationController _burn;
  late final Ticker _clock;
  final ValueNotifier<double> _time = ValueNotifier(0);
  Timer? _haptics;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _burn = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_completed) {
          _completed = true;
          _haptics?.cancel();
          HapticFeedback.heavyImpact();
          widget.onBurned();
        }
      });
    _clock = createTicker((elapsed) {
      _time.value = elapsed.inMicroseconds / 1e6;
    })
      ..start();
    _programFuture ??= ui.FragmentProgram.fromAsset('assets/shaders/burn.frag');
    _programFuture!.then((p) {
      if (mounted) setState(() => _program = p);
    });
  }

  void _start() {
    if (_completed) return;
    HapticFeedback.mediumImpact();
    _burn.forward();
    _haptics = Timer.periodic(const Duration(milliseconds: 90), (_) {
      HapticFeedback.selectionClick();
    });
  }

  void _stop() {
    _burn.stop();
    _haptics?.cancel();
  }

  @override
  void dispose() {
    _haptics?.cancel();
    _clock.dispose();
    _burn.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final program = _program;
    if (program == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return AspectRatio(
      aspectRatio: widget.image.width / widget.image.height,
      child: Listener(
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _stop(),
        onPointerCancel: (_) => _stop(),
        child: CustomPaint(
          painter: _BurnPainter(
            shader: program.fragmentShader(),
            image: widget.image,
            progress: _burn,
            time: _time,
          ),
        ),
      ),
    );
  }
}

class _BurnPainter extends CustomPainter {
  _BurnPainter({
    required this.shader,
    required this.image,
    required this.progress,
    required this.time,
  }) : super(repaint: Listenable.merge([progress, time]));

  final ui.FragmentShader shader;
  final ui.Image image;
  final Animation<double> progress;
  final ValueListenable<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, progress.value)
      ..setFloat(3, time.value)
      ..setImageSampler(0, image);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_BurnPainter old) =>
      old.image != image || old.shader != shader;
}

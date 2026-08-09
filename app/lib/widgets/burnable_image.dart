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
    this.onProgress,
    this.duration = const Duration(milliseconds: 3000),
  });

  final ui.Image image;
  final VoidCallback onBurned;

  /// Reports burn progress 0→1 every frame so the host screen can react
  /// (glow, hint fade) without owning the animation.
  final ValueChanged<double>? onProgress;

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
      ..addListener(() => widget.onProgress?.call(_burn.value))
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
    // The canvas is deliberately larger than the paper: flames need air
    // above the burning edge, and a shader can only paint inside its own
    // quad. Without this margin the fire is clipped flat at the edge.
    final w = widget.image.width * (1 + _padLeft + _padRight);
    final h = widget.image.height * (1 + _padTop + _padBottom);
    return AspectRatio(
      aspectRatio: w / h,
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

/// Head-room around the paper, as fractions of its own size. Generous at
/// the top because that's where flames climb.
const double _padTop = 0.34;
const double _padBottom = 0.06;
const double _padLeft = 0.12;
const double _padRight = 0.12;

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
    // Where the paper sits inside the padded quad, in 0..1 coordinates.
    final spanX = 1 + _padLeft + _padRight;
    final spanY = 1 + _padTop + _padBottom;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, progress.value)
      ..setFloat(3, time.value)
      ..setFloat(4, _padLeft / spanX)
      ..setFloat(5, _padTop / spanY)
      ..setFloat(6, (_padLeft + 1) / spanX)
      ..setFloat(7, (_padTop + 1) / spanY)
      ..setImageSampler(0, image);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_BurnPainter old) =>
      old.image != image || old.shader != shader;
}

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'burn_sound.dart';

/// Lets a sibling widget — the Hold-to-burn button — drive the same burn
/// the paper responds to, so there is one animation with two handles on
/// it rather than two competing ones.
class BurnHoldController {
  VoidCallback? _press;
  VoidCallback? _release;

  void press() => _press?.call();
  void release() => _release?.call();
}

/// The burn ritual: press-and-hold dissolves [image] through the GLSL
/// shader with haptic ticks; [onBurned] fires once when fully burned.
class BurnableImage extends StatefulWidget {
  const BurnableImage({
    super.key,
    required this.image,
    required this.onBurned,
    this.shaderAsset = 'assets/shaders/burn.frag',
    this.soundAsset = 'audio/fire.wav',
    this.onProgress,
    this.controller,
    this.duration = const Duration(milliseconds: 3000),
  });

  final ui.Image image;
  final VoidCallback onBurned;

  /// Which burn effect to run. Every shader takes the same uniforms, so
  /// the ritual — hold, haptics, sound, completion — is unchanged by the
  /// choice (see data/burn_effects.dart).
  final String shaderAsset;

  /// The loop that plays while the hold lasts — the chosen effect's own
  /// sound (see data/burn_effects.dart).
  final String soundAsset;

  /// Reports burn progress 0→1 every frame so the host screen can react
  /// (glow, hint fade) without owning the animation.
  final ValueChanged<double>? onProgress;

  /// Optional external handle, so a button can hold the burn too.
  final BurnHoldController? controller;

  final Duration duration;

  @override
  State<BurnableImage> createState() => _BurnableImageState();
}

class _BurnableImageState extends State<BurnableImage>
    with TickerProviderStateMixin {
  /// Compiled shaders, kept per asset for the life of the process —
  /// compiling one costs a visible hitch, and the burn must start the
  /// instant a finger lands.
  static final _programs = <String, Future<ui.FragmentProgram>>{};

  ui.FragmentProgram? _program;
  late final AnimationController _burn;
  late final Ticker _clock;
  final ValueNotifier<double> _time = ValueNotifier(0);
  Timer? _haptics;
  late BurnSound _sound = BurnSound(widget.soundAsset);
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
          _sound.finish();
          HapticFeedback.heavyImpact();
          widget.onBurned();
        }
      });
    widget.controller
      ?.._press = _start
      .._release = _stop;
    _clock = createTicker((elapsed) {
      _time.value = elapsed.inMicroseconds / 1e6;
    })..start();
    _load(widget.shaderAsset);
  }

  void _load(String asset) {
    final future = _programs.putIfAbsent(
      asset,
      () => ui.FragmentProgram.fromAsset(asset),
    );
    future.then((p) {
      // Guard against a swap mid-load resolving after a newer one.
      if (mounted && widget.shaderAsset == asset) {
        setState(() => _program = p);
      }
    });
  }

  @override
  void didUpdateWidget(BurnableImage old) {
    super.didUpdateWidget(old);
    if (old.shaderAsset != widget.shaderAsset) {
      _program = null;
      _load(widget.shaderAsset);
    }
    if (old.soundAsset != widget.soundAsset) {
      _sound.dispose();
      _sound = BurnSound(widget.soundAsset);
    }
  }

  void _start() {
    if (_completed) return;
    HapticFeedback.mediumImpact();
    _sound.start();
    _burn.forward();
    _haptics = Timer.periodic(const Duration(milliseconds: 90), (_) {
      HapticFeedback.selectionClick();
    });
  }

  void _stop() {
    if (_completed) return;
    _burn.stop();
    _haptics?.cancel();
    _sound.pause();
  }

  @override
  void dispose() {
    _haptics?.cancel();
    _sound.dispose();
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
    // This widget occupies exactly the PAPER. The shader quad is larger on
    // every side so flames have air to climb into, but that head-room is
    // transparent and must not take part in layout — let it, and the top
    // margin shows up on screen as a gap above the sheet.
    return LayoutBuilder(
      builder: (context, constraints) {
        const spanX = 1 + _padLeft + _padRight;
        const spanY = 1 + _padTop + _padBottom;
        final aspect = widget.image.width / widget.image.height;

        // Largest sheet that fits the space it was given.
        var paperW = constraints.maxWidth;
        var paperH = paperW / aspect;
        if (paperH > constraints.maxHeight) {
          paperH = constraints.maxHeight;
          paperW = paperH * aspect;
        }

        return SizedBox(
          width: paperW,
          height: paperH,
          child: OverflowBox(
            // Explicit zero minimums: if this ever sits under tight
            // constraints, an inherited minHeight silently overrides the
            // quad and the shader's coordinate mapping goes with it.
            minWidth: 0,
            minHeight: 0,
            maxWidth: paperW * spanX,
            maxHeight: paperH * spanY,
            // The head-room is asymmetric, so centring the quad would paint
            // the sheet off its own box. This lands the quad's paper region
            // exactly on it.
            alignment: _quadAlign,
            child: SizedBox(
              width: paperW * spanX,
              height: paperH * spanY,
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
            ),
          ),
        );
      },
    );
  }
}

/// Head-room around the paper, as fractions of its own size. Now that the
/// burn runs bottom-up, tongues spend most of their life *over* the sheet
/// and only clear the top edge at the very end — so the top margin can be
/// much tighter than it was when fire climbed into empty space.
const double _padTop = 0.20;
const double _padBottom = 0.08;
const double _padLeft = 0.12;
const double _padRight = 0.12;

/// Where to hang the oversized quad so its paper region lands on this
/// widget's box. Alignment places a too-big child by `(1 + a) / 2` of the
/// (negative) overflow, so the fraction below is the share of the overflow
/// that belongs above the sheet.
const Alignment _quadAlign = Alignment(
  2 * _padLeft / (_padLeft + _padRight) - 1,
  2 * _padTop / (_padTop + _padBottom) - 1,
);

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

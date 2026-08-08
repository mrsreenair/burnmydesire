// Burn My Desire — Phase 0 shader spike.
// One image, press-and-hold to burn it with the GLSL shader, haptics on the way.
// Goal: judge whether the ritual feels visceral at 60fps. Throwaway code.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const SpikeApp());

class SpikeApp extends StatefulWidget {
  const SpikeApp({super.key});

  @override
  State<SpikeApp> createState() => _SpikeAppState();
}

class _SpikeAppState extends State<SpikeApp> {
  bool _showPerf = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: _showPerf,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: BurnPage(
        onTogglePerf: () => setState(() => _showPerf = !_showPerf),
      ),
    );
  }
}

class BurnPage extends StatefulWidget {
  const BurnPage({super.key, required this.onTogglePerf});

  final VoidCallback onTogglePerf;

  @override
  State<BurnPage> createState() => _BurnPageState();
}

class _BurnPageState extends State<BurnPage>
    with TickerProviderStateMixin {
  ui.FragmentProgram? _program;
  ui.Image? _image;
  late final AnimationController _burn;
  late final Ticker _clock;
  final ValueNotifier<double> _time = ValueNotifier(0);
  Timer? _haptics;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _burn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _onBurnedDown();
      });
    _clock = createTicker((elapsed) {
      _time.value = elapsed.inMicroseconds / 1e6;
    })
      ..start();
    _load();
  }

  Future<void> _load() async {
    final program = await ui.FragmentProgram.fromAsset('shaders/burn.frag');
    final image = await _makePlaceholder();
    setState(() {
      _program = program;
      _image = image;
    });
  }

  // Fake "product photo" so the spike needs no bundled assets.
  Future<ui.Image> _makePlaceholder() async {
    const w = 900.0, h = 1200.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(w, h),
            [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)]),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(150, 220, 600, 560),
          const Radius.circular(40)),
      Paint()..color = const Color(0xFFECF0F1),
    );
    c.drawCircle(
        const Offset(450, 460), 150, Paint()..color = const Color(0xFFE67E22));
    c.drawCircle(
        const Offset(450, 460), 90, Paint()..color = const Color(0xFF2C3E50));
    c.drawRect(const Rect.fromLTWH(210, 690, 480, 50),
        Paint()..color = const Color(0xFF95A5A6));
    final tp = TextPainter(
      text: const TextSpan(
        text: '3D PRINTER\n€800',
        style: TextStyle(
            fontSize: 96, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: w);
    tp.paint(c, const Offset(0, 880));
    return rec.endRecording().toImage(w.toInt(), h.toInt());
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (picked == null) return;
    final image = await decodeImageFromList(await picked.readAsBytes());
    setState(() {
      _image = image;
      _reset();
    });
  }

  void _startBurn() {
    if (_done) return;
    HapticFeedback.mediumImpact();
    _burn.forward();
    _haptics = Timer.periodic(const Duration(milliseconds: 90), (_) {
      HapticFeedback.selectionClick();
    });
  }

  void _stopBurn() {
    _burn.stop();
    _haptics?.cancel();
  }

  void _onBurnedDown() {
    _haptics?.cancel();
    HapticFeedback.heavyImpact();
    setState(() => _done = true);
  }

  void _reset() {
    _haptics?.cancel();
    _burn.value = 0;
    _done = false;
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
    final image = _image;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Burn spike'),
        actions: [
          IconButton(
              onPressed: widget.onTogglePerf,
              icon: const Icon(Icons.speed),
              tooltip: 'Performance overlay'),
          IconButton(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_library_outlined),
              tooltip: 'Pick photo'),
        ],
      ),
      body: program == null || image == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AspectRatio(
                        aspectRatio: image.width / image.height,
                        child: Listener(
                          onPointerDown: (_) => _startBurn(),
                          onPointerUp: (_) => _stopBurn(),
                          onPointerCancel: (_) => _stopBurn(),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CustomPaint(
                                painter: _BurnPainter(
                                  shader: program.fragmentShader(),
                                  image: image,
                                  progress: _burn,
                                  time: _time,
                                ),
                              ),
                              if (_done)
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('🔥 BURNED',
                                          style: TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 12),
                                      FilledButton(
                                        onPressed: () =>
                                            setState(_reset),
                                        child: const Text('Reset'),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    _done
                        ? 'Desire destroyed.'
                        : 'Press and hold the image to burn it',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
              ],
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

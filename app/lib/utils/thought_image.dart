import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

const _width = 900.0;
const _height = 1200.0;
const _margin = 80.0;
const _lineGap = 64.0;
const _firstLineY = 180.0;

/// Renders a written thought onto ruled paper and returns it as a PNG —
/// the burn shader then treats it like any other image. The thought
/// itself never leaves the device.
Future<Uint8List> renderThoughtImage(String text) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // Warm paper.
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, _width, _height),
    ui.Paint()..color = const ui.Color(0xFFF6EFDF),
  );

  // Ruled lines and a red margin line, like a torn notebook page.
  final rule = ui.Paint()
    ..color = const ui.Color(0x26715B33)
    ..strokeWidth = 2;
  for (var y = _firstLineY; y < _height - 60; y += _lineGap) {
    canvas.drawLine(ui.Offset(_margin - 20, y), ui.Offset(_width - 60, y), rule);
  }
  canvas.drawLine(
    const ui.Offset(_margin + 20, 60),
    const ui.Offset(_margin + 20, _height - 60),
    ui.Paint()
      ..color = const ui.Color(0x33B0463C)
      ..strokeWidth = 3,
  );

  // The thought, in handwriting-ish ink sitting on the rules.
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        color: ui.Color(0xFF33291C),
        fontSize: 42,
        fontStyle: FontStyle.italic,
        height: _lineGap / 42,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: _width - _margin * 2 - 40);
  painter.paint(canvas, ui.Offset(_margin + 40, _firstLineY - 50));

  final image = await recorder
      .endRecording()
      .toImage(_width.toInt(), _height.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

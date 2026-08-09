import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'format_utils.dart';

const _size = 1080.0;

/// Renders a shareable "€X protected" card.
///
/// Deliberately says nothing about *what* was resisted — only the amount
/// and the streak. Someone sharing a win must never accidentally share
/// that they're fighting an addiction.
Future<Uint8List> renderMilestoneCard({
  required int protectedCents,
  required int burns,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const rect = ui.Rect.fromLTWH(0, 0, _size, _size);

  // Warm paper, the same world the app lives in.
  canvas.drawRect(rect, ui.Paint()..color = const ui.Color(0xFFF7F3EC));
  canvas.drawCircle(
    const ui.Offset(_size * 0.85, _size * 0.16),
    _size * 0.34,
    ui.Paint()..color = const ui.Color(0x22FF6B35),
  );
  canvas.drawCircle(
    const ui.Offset(_size * 0.1, _size * 0.92),
    _size * 0.28,
    ui.Paint()..color = const ui.Color(0x1A1E9E6A),
  );

  void write(
    String text,
    double top,
    double size,
    ui.Color color, {
    FontWeight weight = FontWeight.w800,
    double letterSpacing = -1,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _size * 0.82);
    painter.paint(canvas, ui.Offset((_size - painter.width) / 2, top));
  }

  write('🔥', 150, 96, const ui.Color(0xFF1A1A1A), letterSpacing: 0);
  write('I protected', 300, 52, const ui.Color(0xFF6B6257),
      weight: FontWeight.w600, letterSpacing: 0);
  write(formatEuros(protectedCents), 370, 148,
      const ui.Color(0xFF1E9E6A));
  write(
    burns == 1
        ? 'by burning one desire\ninstead of buying it'
        : 'by burning $burns desires\ninstead of buying them',
    560,
    46,
    const ui.Color(0xFF3A342C),
    weight: FontWeight.w600,
    letterSpacing: 0,
  );
  write('Burn My Desire', _size - 190, 40, const ui.Color(0xFF1A1A1A),
      letterSpacing: -0.5);
  write('burnmydesire.com', _size - 130, 32, const ui.Color(0xFF9A9186),
      weight: FontWeight.w500, letterSpacing: 0);

  final image =
      await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

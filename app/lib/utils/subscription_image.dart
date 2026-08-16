import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'math_utils.dart';

const _width = 900.0;
const _height = 1500.0;

/// Renders a subscription as a card that can be burned.
///
/// A subscription has nothing to photograph — no box, no product shot,
/// just a line on a statement. So the app draws the thing it actually is:
/// a payment card with the name and what it takes every month. That's the
/// object the fire consumes, and it reads as a card being cut up, which
/// is exactly the gesture.
Future<Uint8List> renderSubscriptionImage({
  required String name,
  required String amountLabel,
  required BillingPeriod period,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, _width, _height),
    ui.Paint()..color = const ui.Color(0xFFF6EFDF),
  );

  // The card itself, sitting on the paper.
  const cardRect = ui.RRect.fromLTRBXY(70, 430, 830, 930, 44, 44);
  canvas.drawRRect(
    cardRect.shift(const ui.Offset(0, 10)),
    ui.Paint()
      ..color = const ui.Color(0x1A33291C)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 18),
  );
  canvas.drawRRect(cardRect, ui.Paint()..color = const ui.Color(0xFF1B1A18));

  // The chip, because a card without one doesn't read as a card.
  canvas.drawRRect(
    ui.RRect.fromRectXY(const ui.Rect.fromLTWH(130, 530, 110, 86), 14, 14),
    ui.Paint()..color = const ui.Color(0xFFC9A227),
  );

  void text(
    String value,
    double x,
    double y, {
    required double size,
    required ui.Color color,
    FontWeight weight = FontWeight.w700,
  }) {
    TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(color: color, fontSize: size, fontWeight: weight),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )
      ..layout(maxWidth: _width - x - 90)
      ..paint(canvas, ui.Offset(x, y));
  }

  final per = switch (period) {
    BillingPeriod.weekly => 'every week',
    BillingPeriod.monthly => 'every month',
    BillingPeriod.yearly => 'every year',
  };

  text(name, 130, 660, size: 54, color: const ui.Color(0xFFF6EFDF));
  text(
    amountLabel,
    130,
    760,
    size: 76,
    color: const ui.Color(0xFFFF7A18),
    weight: FontWeight.w800,
  );
  text(
    per,
    130,
    862,
    size: 34,
    color: const ui.Color(0xFF8A867D),
    weight: FontWeight.w600,
  );

  text(
    'Forever, until you cancel',
    130,
    1010,
    size: 34,
    color: const ui.Color(0xFF8A867D),
    weight: FontWeight.w600,
  );

  final image = await recorder.endRecording().toImage(
    _width.toInt(),
    _height.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

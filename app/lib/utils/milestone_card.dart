import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'format_utils.dart';

/// The shapes a share card comes in.
///
/// Square is the feed post. Story is what Instagram Stories, Reels and
/// TikTok actually want — a square dropped into a Story sits in a
/// letterboxed band with dead space above and below it, which reads as
/// someone who didn't bother.
enum CardFormat {
  square(1080, 1080, 190),
  story(1080, 1920, 320);

  const CardFormat(this.width, this.height, this.footerInset);

  final double width;
  final double height;

  /// How far the wordmark sits above the bottom edge. Stories need more
  /// room than a feed post, because the platform's own controls sit over
  /// the bottom of the frame.
  final double footerInset;
}

/// Renders a shareable "€X protected" card.
///
/// Deliberately says nothing about *what* was resisted — only the amount
/// and the streak. Someone sharing a win must never accidentally share
/// that they're fighting an addiction.
Future<Uint8List> renderMilestoneCard({
  required int protectedCents,
  required int burns,
  CardFormat format = CardFormat.square,
}) async {
  final w = format.width;
  final h = format.height;

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // Warm paper, the same world the app lives in.
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, w, h),
    ui.Paint()..color = const ui.Color(0xFFF7F3EC),
  );
  // Radii track the width so the washes stay the same size in both
  // formats; only their vertical placement stretches with the frame.
  canvas.drawCircle(
    ui.Offset(w * 0.85, h * 0.16),
    w * 0.34,
    ui.Paint()..color = const ui.Color(0x22FF6B35),
  );
  canvas.drawCircle(
    ui.Offset(w * 0.1, h * 0.92),
    w * 0.28,
    ui.Paint()..color = const ui.Color(0x1A1E9E6A),
  );

  TextPainter measure(
    String text,
    double size,
    ui.Color color, {
    FontWeight weight = FontWeight.w800,
    double letterSpacing = -1,
  }) {
    return TextPainter(
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
    )..layout(maxWidth: w * 0.82);
  }

  void paintAt(TextPainter painter, double top) {
    painter.paint(canvas, ui.Offset((w - painter.width) / 2, top));
  }

  // The stack is measured before it is painted, so the same copy can be
  // centred in a square or a story frame without hand-tuned offsets per
  // format — and so a long amount pushing to two lines still balances.
  final flame = measure('🔥', 96, const ui.Color(0xFF1A1A1A), letterSpacing: 0);
  final lead = measure(
    'I protected',
    52,
    const ui.Color(0xFF6B6257),
    weight: FontWeight.w600,
    letterSpacing: 0,
  );
  final amount = measure(
    formatMoney(protectedCents),
    148,
    const ui.Color(0xFF1E9E6A),
  );
  final tail = measure(
    burns == 1
        ? 'by burning one desire\ninstead of buying it'
        : 'by burning $burns desires\ninstead of buying them',
    46,
    const ui.Color(0xFF3A342C),
    weight: FontWeight.w600,
    letterSpacing: 0,
  );

  const gapAfterFlame = 44.0;
  const gapAfterLead = 13.0;
  const gapAfterAmount = 27.0;
  final blockHeight =
      flame.height +
      gapAfterFlame +
      lead.height +
      gapAfterLead +
      amount.height +
      gapAfterAmount +
      tail.height;

  // Centred in the space above the wordmark, not the whole frame, so the
  // footer never crowds the number.
  final footerTop = h - format.footerInset;
  var y = (footerTop - blockHeight) / 2;

  paintAt(flame, y);
  y += flame.height + gapAfterFlame;
  paintAt(lead, y);
  y += lead.height + gapAfterLead;
  paintAt(amount, y);
  y += amount.height + gapAfterAmount;
  paintAt(tail, y);

  paintAt(
    measure(
      'Burn My Desire',
      40,
      const ui.Color(0xFF1A1A1A),
      letterSpacing: -0.5,
    ),
    footerTop,
  );
  paintAt(
    measure(
      'burnmydesire.com',
      32,
      const ui.Color(0xFF9A9186),
      weight: FontWeight.w500,
      letterSpacing: 0,
    ),
    footerTop + 60,
  );

  final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

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

/// The destination, for the goal line: what the money is for and how far
/// along it is. A goal is aspirational, so it's safe to share where a
/// temptation never would be.
class MilestoneGoal {
  const MilestoneGoal({
    required this.name,
    required this.emoji,
    required this.percent,
  });

  final String name;
  final String emoji;

  /// Whole percent, 0–100.
  final int percent;
}

/// Renders a shareable "€X protected" card.
///
/// Deliberately says nothing about *what* was resisted — only the amount
/// and the streak. Someone sharing a win must never accidentally share
/// that they're fighting an addiction.
///
/// With a [goal] it adds the line people actually post — "✈️ A trip · 5%"
/// with a progress bar (GROWTH.md M3): the number is the brag, the goal
/// is theirs. With no money at all ([protectedCents] ≤ 0) and some
/// [thoughts], it becomes the thought-burner's card: how many things were
/// let go of, and still nothing about what they were.
Future<Uint8List> renderMilestoneCard({
  required int protectedCents,
  required int burns,
  int thoughts = 0,
  MilestoneGoal? goal,
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
  final thoughtsOnly = protectedCents <= 0 && thoughts > 0;

  final flame = measure('🔥', 96, const ui.Color(0xFF1A1A1A), letterSpacing: 0);
  final lead = measure(
    thoughtsOnly ? 'I let go of' : 'I protected',
    52,
    const ui.Color(0xFF6B6257),
    weight: FontWeight.w600,
    letterSpacing: 0,
  );
  final amount = measure(
    thoughtsOnly ? '$thoughts' : formatMoney(protectedCents),
    148,
    thoughtsOnly ? const ui.Color(0xFFFF6B35) : const ui.Color(0xFF1E9E6A),
  );
  final tail = measure(
    thoughtsOnly
        ? (thoughts == 1
              ? 'thought I was carrying,\nby burning it'
              : 'thoughts I was carrying,\nby burning them')
        : burns == 1
        ? 'by burning one desire\ninstead of buying it'
        : 'by burning $burns desires\ninstead of buying them',
    46,
    const ui.Color(0xFF3A342C),
    weight: FontWeight.w600,
    letterSpacing: 0,
  );

  // The goal line: a soft card with emoji + name on the left, the
  // percent on the right, and a bar underneath. Only for money cards
  // with a goal — a thought burn bringing a MacBook closer is the wrong
  // note, on the share as much as on the victory screen.
  final showGoal = goal != null && !thoughtsOnly;
  final goalCardW = w * 0.82;
  const goalCardH = 150.0;
  const gapAfterTail = 40.0;

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
      tail.height +
      (showGoal ? gapAfterTail + goalCardH : 0);

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
  y += tail.height;

  if (showGoal) {
    y += gapAfterTail;
    final left = (w - goalCardW) / 2;
    final card = ui.RRect.fromRectXY(
      ui.Rect.fromLTWH(left, y, goalCardW, goalCardH),
      32,
      32,
    );
    canvas.drawRRect(card, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
    canvas.drawRRect(
      card,
      ui.Paint()
        ..color = const ui.Color(0x141A1A1A)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    const pad = 34.0;
    final name = TextPainter(
      text: TextSpan(
        text: '${goal.emoji}  ${goal.name}',
        style: const TextStyle(
          color: ui.Color(0xFF1A1A1A),
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: goalCardW - pad * 2 - 160);
    final pct = TextPainter(
      text: TextSpan(
        text: '${goal.percent}%',
        style: const TextStyle(
          color: ui.Color(0xFF1E9E6A),
          fontSize: 40,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    name.paint(canvas, ui.Offset(left + pad, y + 26));
    pct.paint(canvas, ui.Offset(left + goalCardW - pad - pct.width, y + 26));

    // The bar. Its fill is a fraction of a real width, so 5 % is a
    // visible nub rather than nothing — the same as the app's own bar.
    final barTop = y + goalCardH - pad - 16;
    final barW = goalCardW - pad * 2;
    final track = ui.RRect.fromRectXY(
      ui.Rect.fromLTWH(left + pad, barTop, barW, 16),
      8,
      8,
    );
    canvas.drawRRect(track, ui.Paint()..color = const ui.Color(0xFFEDEAE3));
    final fillW = (barW * goal.percent / 100).clamp(16.0, barW);
    canvas.drawRRect(
      ui.RRect.fromRectXY(
        ui.Rect.fromLTWH(left + pad, barTop, fillW, 16),
        8,
        8,
      ),
      ui.Paint()..color = const ui.Color(0xFF1E9E6A),
    );
  }

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

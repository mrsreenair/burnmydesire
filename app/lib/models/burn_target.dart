import 'dart:typed_data';
import 'dart:ui' as ui;

import '../utils/math_utils.dart';

/// What's about to be burned: either a brand-new temptation from the capture
/// flow ([itemId] null) or a stored item being re-burned ([itemId] set).
class BurnTarget {
  const BurnTarget({
    this.itemId,
    required this.image,
    required this.imageBytes,
    required this.priceCents,
    this.plan,
  });

  final int? itemId;
  final ui.Image image;
  final Uint8List imageBytes;
  final int priceCents;
  final InstallmentPlan? plan;
}

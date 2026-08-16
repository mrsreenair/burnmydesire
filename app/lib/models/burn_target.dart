import 'dart:typed_data';
import 'dart:ui' as ui;

import '../data/reflection.dart';
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
    this.category = 'purchase',
    this.burnNumber = 1,
    this.letGoForever = false,
    this.thoughtText,
    this.reflection = const [],
    this.recurringCents,
    this.billingPeriod,
  });

  final int? itemId;
  final ui.Image image;
  final Uint8List imageBytes;
  final int priceCents;
  final InstallmentPlan? plan;

  /// 'purchase' (money framing), 'emotion' (written thought, no price),
  /// or 'subscription' (a recurring charge, priced by the year).
  final String category;

  /// For a subscription: what it takes each billing period. [priceCents]
  /// still holds a single year of it — that's the honest unit for the
  /// ledger, while the damage screen shows what the stream really costs.
  final int? recurringCents;

  final BillingPeriod? billingPeriod;

  /// Resistance count this burn will reach (1 for a first burn; for
  /// re-burns the stored count + 1). Drives streak messaging.
  final int burnNumber;

  /// The user chose to end this desire now (long-press on home) rather
  /// than waiting for the automatic final burn.
  final bool letGoForever;

  /// What was written on the burned page (fresh emotion burns only). Fed
  /// to the on-device AI coach; never persisted, never leaves the device.
  final String? thoughtText;

  /// The purchase-interview answers. For a fresh capture these were given
  /// minutes ago and get persisted with the item; for a re-burn they're
  /// the stored answers from last time, shown back as the user's own
  /// words.
  final List<ReflectionQA> reflection;

  bool get isEmotion => category == 'emotion';

  bool get isSubscription => category == 'subscription';
}

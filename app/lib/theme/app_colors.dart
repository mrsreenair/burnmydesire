import 'package:flutter/material.dart';

/// The "Paper & Fire" palette (Canopi-inspired).
///
/// The app lives on warm paper: cream background with soft pastel washes,
/// white physical cards, huge black type, one orange accent. Fire is the
/// only saturated thing — and the burn ritual itself flips to [night],
/// the single dark moment in the app.
///
/// Rules:
/// * [accent] orange = fire and primary action. Use sparingly.
/// * [money] green means "wealth you kept". Never a button color.
/// * Thoughts are [sticky] yellow notes; purchases are white photo cards.
class AppColors {
  const AppColors._();

  // Paper world
  static const paper = Color(0xFFF7F4EE);
  static const paperHigh = Color(0xFFFFFFFF);
  static const field = Color(0xFFEDEAE3); // grey pill inputs
  static const washMint = Color(0xFFDCEFE2);
  static const washPeach = Color(0xFFF9E4D8);
  static const washLilac = Color(0xFFE9E4F2);
  static const sticky = Color(0xFFF7E8A4);
  static const stickyInk = Color(0xFF6B5D2E);

  // Ink
  static const ink = Color(0xFF161513);
  static const inkSoft = Color(0xFF43413C);
  static const textMid = Color(0xFF8A867D);
  static const textLow = Color(0xFFB3AFA6);
  static const hairline = Color(0x14161513);

  // Fire
  static const accent = Color(0xFFFF6B2C);
  static const ember = Color(0xFFFF7A18);
  static const flame = Color(0xFFFF3B2F);
  static const spark = Color(0xFFFFC46B);
  static const coal = Color(0xFFA8102A);

  // Money
  static const money = Color(0xFF17A567);
  static const moneyDeep = Color(0xFF0D7A4B);

  /// The final burn — a desire destroyed forever earns gold.
  static const gold = Color(0xFFB8860B);

  // The ritual room (burn screen only)
  static const night = Color(0xFF0A0709);

  /// Fire gradient — CTAs that lead to the burn, and the shock number.
  static const emberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ember, flame],
  );

  /// Money gradient for protected-wealth numbers on paper.
  static const wealthGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [money, moneyDeep],
  );

  /// The soft physical-card shadow every white card sits on.
  static List<BoxShadow> cardShadow({double opacity = 0.10}) => [
        BoxShadow(
          color: const Color(0xFF3A342A).withValues(alpha: opacity),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: const Color(0xFF3A342A).withValues(alpha: opacity * 0.5),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Glow cast by anything on fire (dark ritual screens).
  static List<BoxShadow> emberGlow({double opacity = 0.45, double blur = 32}) =>
      [
        BoxShadow(
          color: flame.withValues(alpha: opacity),
          blurRadius: blur,
          spreadRadius: -6,
          offset: const Offset(0, 10),
        ),
      ];
}

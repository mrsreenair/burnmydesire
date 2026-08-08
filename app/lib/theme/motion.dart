import 'package:flutter/material.dart';

/// One motion vocabulary for the whole app, so every screen accelerates
/// and settles the same way.
///
/// Timing philosophy: the app is used mid-craving. Transitions are quick
/// (nothing above 420ms on the critical path) but always eased-out, never
/// linear — abrupt motion reads as cheap, slow motion reads as friction.
class Motion {
  const Motion._();

  static const instant = Duration(milliseconds: 120);
  static const fast = Duration(milliseconds: 200);
  static const base = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 520);
  static const reveal = Duration(milliseconds: 900);

  /// Default easing: fast start, long soft landing.
  static const easeOut = Cubic(0.16, 1, 0.3, 1);

  /// For things that grow into place (numbers, glows, badges).
  static const spring = Cubic(0.34, 1.46, 0.64, 1);

  static const easeInOut = Cubic(0.65, 0, 0.35, 1);
}

/// Standard push: content fades up and scales in a hair, the outgoing
/// page falls back. Reads as depth without a hard iOS slide.
Route<T> emberRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: Motion.base,
    reverseTransitionDuration: Motion.fast,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Motion.easeOut,
        reverseCurve: Curves.easeIn,
      );
      final out = CurvedAnimation(parent: secondary, curve: Motion.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween(begin: 0.985, end: 1.0).animate(curved),
            child: FadeTransition(
              opacity: Tween(begin: 1.0, end: 0.0).animate(out),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

/// Entering the fire: a slower dissolve through black, so the burn screen
/// feels like the room lights going out.
Route<T> fireRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: Motion.slow,
    reverseTransitionDuration: Motion.base,
    opaque: true,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Motion.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 1.06, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

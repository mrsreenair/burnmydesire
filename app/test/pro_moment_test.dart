import 'package:burn_my_desire/data/pro_moment.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Pro moment (GROWTH.md M2): offered after a burn worth more than
/// Pro itself, and only then. Every rule that keeps it rare lives here.
void main() {
  final now = DateTime(2026, 8, 16, 12);

  bool due({
    int burnCents = 24900,
    double eurosPerUnit = 1.0,
    bool isEmotion = false,
    bool isPro = false,
    bool storeAvailable = true,
    bool anotherAskShowing = false,
    int victoriesBefore = 3,
    DateTime? lastShownAt,
  }) => ProMoment.eligible(
    burnCents: burnCents,
    eurosPerUnit: eurosPerUnit,
    isEmotion: isEmotion,
    isPro: isPro,
    storeAvailable: storeAvailable,
    anotherAskShowing: anotherAskShowing,
    victoriesBefore: victoriesBefore,
    lastShownAt: lastShownAt,
    now: now,
  );

  test('a €249 burn on the fourth victory earns the card', () {
    expect(due(), isTrue);
  });

  test('never on the first burn — that win is theirs alone', () {
    expect(due(victoriesBefore: 0), isFalse);
    expect(due(victoriesBefore: 1), isTrue);
  });

  test('never for a thought, never for Pro, never without a store', () {
    expect(due(isEmotion: true), isFalse);
    expect(due(isPro: true), isFalse);
    expect(due(storeAvailable: false), isFalse);
  });

  test('waits its turn behind the permission asks', () {
    expect(due(anotherAskShowing: true), isFalse);
  });

  test('only when the burn is worth about what Pro costs', () {
    // €29 in euros: no. €30: yes. The line on the card must be true.
    expect(due(burnCents: 2900), isFalse);
    expect(due(burnCents: 3000), isTrue);
    expect(due(burnCents: 0), isFalse);
  });

  test('the threshold is in rough euros, not in local units', () {
    // ₹3,000 is about €29 — not enough. ₹30,000 is.
    expect(due(burnCents: 300000, eurosPerUnit: 0.0098), isFalse);
    expect(due(burnCents: 3000000, eurosPerUnit: 0.0098), isTrue);
    // $35 is about €30.
    expect(due(burnCents: 3500, eurosPerUnit: 0.86), isTrue);
    expect(due(burnCents: 3400, eurosPerUnit: 0.86), isFalse);
  });

  test('a fortnight of quiet after every showing, tapped or not', () {
    expect(due(lastShownAt: now.subtract(const Duration(days: 13))), isFalse);
    expect(due(lastShownAt: now.subtract(const Duration(days: 14))), isTrue);
    expect(due(lastShownAt: now.subtract(const Duration(days: 40))), isTrue);
  });
}

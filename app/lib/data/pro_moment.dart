import 'package:shared_preferences/shared_preferences.dart';

/// The one moment Pro is offered unasked: right after a burn worth more
/// than Pro itself (GROWTH.md M2).
///
/// The paywall is otherwise reachable only from Settings and a capture
/// limit most people never hit. That's deliberate — the ritual is never
/// held hostage — but it means the app never *mentions* Pro at the one
/// time it's welcome: after a win, with the user's own number on screen
/// ("You just protected €249"). Same placement rule as "move the money":
/// after the burn, never on the shock card, never mid-craving.
///
/// The rules are pure and tested; the prefs below just remember when it
/// was last shown and how many victories there have been.
class ProMoment {
  /// The burn must be worth at least this, in rough euros, before the
  /// card appears — about the lifetime price, so "one burn pays for it"
  /// is arithmetically true when the card says it. Uses the currency's
  /// approximate EUR rate, never shown, only compared.
  static const minEuros = 30.0;

  /// How long after showing it once before it may appear again. Two
  /// weeks: long enough that it never reads as nagging, short enough to
  /// still catch the next big burn.
  static const cooldown = Duration(days: 14);

  static bool eligible({
    required int burnCents,
    required double eurosPerUnit,
    required bool isEmotion,
    required bool isPro,
    required bool storeAvailable,
    required bool anotherAskShowing,
    required int victoriesBefore,
    required DateTime? lastShownAt,
    required DateTime now,
  }) {
    if (isPro || !storeAvailable) return false;
    // A thought burn is not a moment to be sold anything.
    if (isEmotion) return false;
    // Two cards under a win turn a celebration into a consent form; the
    // permission asks come first, this waits for another burn.
    if (anotherAskShowing) return false;
    // Never on the very first burn: the first victory is theirs alone.
    if (victoriesBefore < 1) return false;
    if (burnCents <= 0) return false;
    if ((burnCents / 100) * eurosPerUnit < minEuros) return false;
    if (lastShownAt != null && now.difference(lastShownAt) < cooldown) {
      return false;
    }
    return true;
  }
}

const _kLastShownKey = 'pro_moment_last_shown';
const _kVictoriesKey = 'victories_seen';

Future<DateTime?> proMomentLastShown() async {
  final ms = (await SharedPreferences.getInstance()).getInt(_kLastShownKey);
  return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}

/// Marks the moment as *shown* — not tapped. A dismissal counts; the
/// cooldown exists so a "no" is respected for a fortnight.
Future<void> markProMomentShown(DateTime when) async =>
    (await SharedPreferences.getInstance()).setInt(
      _kLastShownKey,
      when.millisecondsSinceEpoch,
    );

/// How many victory screens this install has seen. Cheaper and more
/// honest than reconstructing it from the ledger, which the erase and
/// restore paths can change under us.
Future<int> victoriesSeen() async =>
    (await SharedPreferences.getInstance()).getInt(_kVictoriesKey) ?? 0;

Future<void> bumpVictoriesSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kVictoriesKey, (prefs.getInt(_kVictoriesKey) ?? 0) + 1);
}

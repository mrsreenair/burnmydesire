import 'package:shared_preferences/shared_preferences.dart';

/// What the user is saving *for*. One goal, by design: a single
/// destination keeps every burn pointed at the same picture, which is
/// the entire retention idea — "you protected money" is abstract,
/// "you're 4% closer to your car" is a place to get to.
///
/// Stored in prefs, not the database: it's a setting, not a record, and
/// there is exactly one.
class FinancialGoal {
  const FinancialGoal({
    required this.name,
    required this.emoji,
    required this.targetCents,
  });

  final String name;
  final String emoji;

  /// The price of the dream, in the user's own minor units. Never
  /// converted — like every amount in the app.
  final int targetCents;

  /// Whole-percent progress, honestly capped at 100.
  int percentOf(int protectedCents) {
    if (targetCents <= 0) return 0;
    return ((protectedCents * 100) ~/ targetCents).clamp(0, 100);
  }

  bool reachedBy(int protectedCents) => protectedCents >= targetCents;
}

/// Preset dreams: (name, emoji). Priced by the user, not by us — a car
/// means a very different number in Mumbai and in Munich.
const goalPresets = <(String, String)>[
  ('A car', '🚗'),
  ('A place of my own', '🏡'),
  ('A MacBook', '💻'),
  ('A trip', '✈️'),
  ('An emergency fund', '🛟'),
  ('College', '🎓'),
  ('A wedding', '💍'),
  ('Just growing my savings', '🌱'),
];

const _kGoalNameKey = 'financial_goal_name';
const _kGoalEmojiKey = 'financial_goal_emoji';
const _kGoalTargetKey = 'financial_goal_target_cents';

Future<FinancialGoal?> savedFinancialGoal() async {
  final prefs = await SharedPreferences.getInstance();
  final name = prefs.getString(_kGoalNameKey);
  final target = prefs.getInt(_kGoalTargetKey) ?? 0;
  if (name == null || name.isEmpty || target <= 0) return null;
  return FinancialGoal(
    name: name,
    emoji: prefs.getString(_kGoalEmojiKey) ?? '🌱',
    targetCents: target,
  );
}

Future<void> saveFinancialGoal(FinancialGoal goal) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kGoalNameKey, goal.name);
  await prefs.setString(_kGoalEmojiKey, goal.emoji);
  await prefs.setInt(_kGoalTargetKey, goal.targetCents);
}

Future<void> clearFinancialGoal() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kGoalNameKey);
  await prefs.remove(_kGoalEmojiKey);
  await prefs.remove(_kGoalTargetKey);
}

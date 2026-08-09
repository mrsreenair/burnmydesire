import 'package:burn_my_desire/data/financial_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const goal = FinancialGoal(
    name: 'A MacBook',
    emoji: '💻',
    targetCents: 200000, // 2,000 in whole units
  );

  group('progress', () {
    test('whole percents, capped at 100', () {
      expect(goal.percentOf(0), 0);
      expect(goal.percentOf(4600), 2); // 46 of 2,000 = 2.3% → 2
      expect(goal.percentOf(100000), 50);
      expect(goal.percentOf(200000), 100);
      expect(goal.percentOf(999999999), 100);
    });

    test('reached exactly at the target', () {
      expect(goal.reachedBy(199999), isFalse);
      expect(goal.reachedBy(200000), isTrue);
    });

    test('a broken zero target can never divide by zero', () {
      const broken = FinancialGoal(name: 'x', emoji: 'x', targetCents: 0);
      expect(broken.percentOf(5000), 0);
    });
  });

  group('persistence', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('nothing saved means no goal', () async {
      expect(await savedFinancialGoal(), isNull);
    });

    test('round-trips and clears', () async {
      await saveFinancialGoal(goal);
      final loaded = await savedFinancialGoal();
      expect(loaded!.name, 'A MacBook');
      expect(loaded.emoji, '💻');
      expect(loaded.targetCents, 200000);

      await clearFinancialGoal();
      expect(await savedFinancialGoal(), isNull);
    });

    test('a corrupt zero target reads as no goal', () async {
      await saveFinancialGoal(
        const FinancialGoal(name: 'x', emoji: 'x', targetCents: 0),
      );
      expect(await savedFinancialGoal(), isNull);
    });
  });
}

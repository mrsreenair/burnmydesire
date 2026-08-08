import 'package:burn_my_desire/data/user_prefs.dart';
import 'package:burn_my_desire/utils/motivation.dart';
import 'package:burn_my_desire/utils/thought_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('burn goals prefs', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('round-trip', () async {
      await saveBurnGoals(['alcohol', 'breakup']);
      expect(await savedBurnGoals(), ['alcohol', 'breakup']);
    });

    test('default empty', () async {
      expect(await savedBurnGoals(), isEmpty);
    });

    test('goal ids are unique', () {
      final ids = burnGoals.map((g) => g.$1).toSet();
      expect(ids.length, burnGoals.length);
    });
  });

  group('motivation messages', () {
    test('first burn gets an encouragement', () {
      final msg = motivationMessage(resistanceCount: 1, seed: 3);
      expect(msg, isNotEmpty);
      expect(msg.contains('%N'), isFalse);
    });

    test('streaks mention the count', () {
      final msg = motivationMessage(resistanceCount: 7, seed: 0);
      expect(msg, contains('7'));
      expect(msg.contains('%N'), isFalse);
    });

    test('seed varies the message deterministically', () {
      final a = motivationMessage(resistanceCount: 1, seed: 0);
      final b = motivationMessage(resistanceCount: 1, seed: 1);
      final a2 = motivationMessage(resistanceCount: 1, seed: 0);
      expect(a, isNot(b));
      expect(a, a2);
    });
  });

  group('thought image', () {
    test('renders a PNG', () async {
      final bytes = await renderThoughtImage('I keep texting my ex');
      expect(bytes.length, greaterThan(1000));
      // PNG magic number.
      expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    });
  });
}

import 'dart:math';

import 'package:burn_my_desire/data/user_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('hashPin', () {
    test('is deterministic for same pin and salt', () {
      expect(hashPin('1234', 'salt'), hashPin('1234', 'salt'));
    });

    test('differs by pin', () {
      expect(hashPin('1234', 'salt'), isNot(hashPin('1235', 'salt')));
    });

    test('differs by salt', () {
      expect(hashPin('1234', 'saltA'), isNot(hashPin('1234', 'saltB')));
    });

    test('never contains the raw pin', () {
      expect(hashPin('1234', 'salt'), isNot(contains('1234')));
    });
  });

  group('generateSalt', () {
    test('produces distinct salts', () {
      final rng = Random(42);
      expect(generateSalt(rng), isNot(generateSalt(rng)));
    });
  });

  group('profile prefs', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('name round-trips trimmed', () async {
      await saveProfileName('  Sree  ');
      expect(await profileName(), 'Sree');
    });

    test('categories round-trip', () async {
      await saveSpendCategories(['Clothes', 'Gadgets']);
      expect(await savedSpendCategories(), ['Clothes', 'Gadgets']);
    });

    test('setup flag defaults false and sticks', () async {
      expect(await hasCompletedSetup(), isFalse);
      await markSetupComplete();
      expect(await hasCompletedSetup(), isTrue);
    });
  });
}

import 'package:burn_my_desire/data/currencies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('codes are unique and lookups work', () {
    expect(
      currencies.map((c) => c.code).toSet().length,
      currencies.length,
    );
    expect(currencyByCode('INR')!.symbol, '₹');
    expect(currencyByCode('XYZ'), isNull);
    expect(currencyByCode(null), isNull);
  });

  test('every currency carries a plausible euro rate', () {
    for (final c in currencies) {
      expect(c.eurosPerUnit, greaterThan(0), reason: c.code);
      // Sanity bounds: no unit currency is worth more than ~2 EUR or
      // less than a hundredth of a cent.
      expect(c.eurosPerUnit, lessThanOrEqualTo(2), reason: c.code);
      expect(c.eurosPerUnit, greaterThan(0.0001), reason: c.code);
    }
  });

  group('detectCurrency', () {
    test('launch markets', () {
      expect(detectCurrency('en_US').code, 'USD');
      expect(detectCurrency('en_IN').code, 'INR');
      expect(detectCurrency('hi_IN').code, 'INR');
      expect(detectCurrency('de_DE').code, 'EUR');
      expect(detectCurrency('fr_FR').code, 'EUR');
      expect(detectCurrency('en_GB').code, 'GBP');
    });

    test('dash and extended locale forms', () {
      expect(detectCurrency('en-IN').code, 'INR');
      expect(detectCurrency('hi_IN@calendar=gregorian').code, 'INR');
    });

    test('unknown regions and bare languages fall back to USD', () {
      expect(detectCurrency('en').code, 'USD');
      expect(detectCurrency('xx_ZZ').code, 'USD');
      expect(detectCurrency('').code, 'USD');
    });
  });
}

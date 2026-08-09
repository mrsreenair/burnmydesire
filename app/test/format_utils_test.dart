import 'package:burn_my_desire/data/currencies.dart';
import 'package:burn_my_desire/utils/format_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Currency c(String code) => currencyByCode(code)!;

  group('formatMoney', () {
    test('euro: comma thousands separators', () {
      setActiveCurrency(c('EUR'));
      expect(formatMoney(168900), '€1,689');
      expect(formatMoney(80000), '€800');
      expect(formatMoney(945100), '€9,451');
      expect(formatMoney(123456789), '€1,234,568');
    });

    test('dollar and rupee symbols follow the active currency', () {
      setActiveCurrency(c('USD'));
      expect(formatMoney(168900), r'$1,689');
      setActiveCurrency(c('INR'));
      expect(formatMoney(168900), '₹1,689');
    });

    test('rupees group by lakh, not thousand', () {
      setActiveCurrency(c('INR'));
      // ₹1,00,000 — writing ₹100,000 would look as foreign to an Indian
      // teen as "1.689 €" did to everyone else.
      expect(formatMoney(10000000), '₹1,00,000');
      expect(formatMoney(1234567800), '₹1,23,45,678');
    });

    test('the world counter total is always euros', () {
      setActiveCurrency(c('INR'));
      expect(formatWorldEuros(168900), '€1,689');
    });
  });

  group('parseMoneyToCents', () {
    setUp(() => setActiveCurrency(c('EUR')));

    test('plain integers', () {
      expect(parseMoneyToCents('800'), 80000);
      expect(parseMoneyToCents(' €1500 '), 150000);
    });

    test('strips any currency marking, not just the active one', () {
      expect(parseMoneyToCents(r'$49.99'), 4999);
      expect(parseMoneyToCents('₹1,299'), 129900);
      expect(parseMoneyToCents('CHF 120'), 12000);
      expect(parseMoneyToCents('1500 kr'), 150000);
    });

    test('dot decimal (English style)', () {
      expect(parseMoneyToCents('799.99'), 79999);
      expect(parseMoneyToCents('799.9'), 79990);
    });

    test('comma decimal (European style)', () {
      expect(parseMoneyToCents('799,99'), 79999);
      expect(parseMoneyToCents('799,9'), 79990);
    });

    test('thousands separators without decimals', () {
      expect(parseMoneyToCents('1,299'), 129900);
      expect(parseMoneyToCents('1.299'), 129900);
      expect(parseMoneyToCents('12,299'), 1229900);
    });

    test('Indian lakh grouping', () {
      expect(parseMoneyToCents('1,00,000'), 10000000);
      expect(parseMoneyToCents('₹12,34,567'), 123456700);
    });

    test('mixed thousands and decimals', () {
      expect(parseMoneyToCents('1,299.50'), 129950);
      expect(parseMoneyToCents('1.299,50'), 129950);
      expect(parseMoneyToCents('1,234,567.89'), 123456789);
    });

    test('rejects non-amounts', () {
      expect(parseMoneyToCents(''), isNull);
      expect(parseMoneyToCents('abc'), isNull);
      expect(parseMoneyToCents('0'), isNull);
      expect(parseMoneyToCents('-50'), isNull);
    });
  });
}

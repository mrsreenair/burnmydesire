import 'package:burn_my_desire/utils/format_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatEuros', () {
    test('uses comma thousands separators', () {
      expect(formatEuros(168900), '€1,689');
      expect(formatEuros(80000), '€800');
      expect(formatEuros(945100), '€9,451');
      expect(formatEuros(123456789), '€1,234,568');
    });
  });

  group('parseEurosToCents', () {
    test('plain integers', () {
      expect(parseEurosToCents('800'), 80000);
      expect(parseEurosToCents(' €1500 '), 150000);
    });

    test('dot decimal (English style)', () {
      expect(parseEurosToCents('799.99'), 79999);
      expect(parseEurosToCents('799.9'), 79990);
    });

    test('comma decimal (European style)', () {
      expect(parseEurosToCents('799,99'), 79999);
      expect(parseEurosToCents('799,9'), 79990);
    });

    test('thousands separators without decimals', () {
      expect(parseEurosToCents('1,299'), 129900);
      expect(parseEurosToCents('1.299'), 129900);
      expect(parseEurosToCents('12,299'), 1229900);
    });

    test('mixed thousands and decimals', () {
      expect(parseEurosToCents('1,299.50'), 129950);
      expect(parseEurosToCents('1.299,50'), 129950);
      expect(parseEurosToCents('1,234,567.89'), 123456789);
    });

    test('rejects non-amounts', () {
      expect(parseEurosToCents(''), isNull);
      expect(parseEurosToCents('abc'), isNull);
      expect(parseEurosToCents('0'), isNull);
      expect(parseEurosToCents('-50'), isNull);
    });
  });
}

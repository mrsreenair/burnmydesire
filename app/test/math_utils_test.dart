import 'package:burn_my_desire/utils/math_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('futureValueCents', () {
    test('€800 at 8% over 20 years is €3,728.77', () {
      expect(futureValueCents(80000, years: 20), 372877);
    });

    test('€800 at 8% over 10 years is €1,727.14', () {
      expect(futureValueCents(80000, years: 10), 172714);
    });

    test('€800 at 8% over 30 years is €8,050.13', () {
      expect(futureValueCents(80000, years: 30), 805013);
    });

    test('zero years returns the principal unchanged', () {
      expect(futureValueCents(80000, years: 0), 80000);
    });

    test('custom rate is honored', () {
      expect(futureValueCents(100000, annualRate: 0.05, years: 10), 162889);
    });
  });

  group('foregoneGrowthCents', () {
    test('is future value minus principal', () {
      expect(foregoneGrowthCents(80000, years: 20), 372877 - 80000);
    });
  });

  group('InstallmentPlan', () {
    const plan = InstallmentPlan(monthlyCents: 7000, months: 12);

    test('total paid is monthly times months', () {
      expect(plan.totalPaidCents, 84000);
    });

    test('overpayment vs sticker price', () {
      expect(plan.overpaymentCents(80000), 4000);
    });

    test('true cost is total paid plus foregone growth', () {
      expect(plan.trueCostCents(80000, years: 20), 84000 + (372877 - 80000));
    });
  });
}

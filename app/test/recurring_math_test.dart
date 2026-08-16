import 'package:burn_my_desire/utils/math_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a year of a subscription, in every billing period', () {
    expect(yearlyCostCents(1200, BillingPeriod.monthly), 14400);
    expect(yearlyCostCents(500, BillingPeriod.weekly), 26000);
    expect(yearlyCostCents(9900, BillingPeriod.yearly), 9900);
  });

  test('a stream compounds far harder than the same money as a lump', () {
    // €12/month for 20 years at 8%: about €7,000 of payments, but every
    // one of them compounds from the day it would have been paid. Treating
    // it as a single lump sum is the mistake this exists to prevent.
    final stream = recurringFutureValueCents(
      1200,
      BillingPeriod.monthly,
      years: 20,
    );
    final paid = recurringTotalPaidCents(
      1200,
      BillingPeriod.monthly,
      years: 20,
    );
    expect(paid, 288000);
    expect(stream, greaterThan(paid * 2));
    // Sanity: a well-known figure — €12/mo at 8% over 20y lands near €7k.
    expect(stream, inInclusiveRange(650000, 750000));
  });

  test('the same yearly spend beats nothing when paid less often', () {
    // €144 once a year vs €12 monthly: monthly wins, because the money
    // starts working sooner. If this ever flips, the maths is wrong.
    final monthly = recurringFutureValueCents(
      1200,
      BillingPeriod.monthly,
      years: 20,
    );
    final yearly = recurringFutureValueCents(
      14400,
      BillingPeriod.yearly,
      years: 20,
    );
    expect(monthly, greaterThan(yearly));
  });

  test('degenerate inputs stay sane', () {
    expect(recurringFutureValueCents(1200, BillingPeriod.monthly, years: 0), 0);
    expect(recurringFutureValueCents(0, BillingPeriod.monthly, years: 20), 0);
    expect(
      recurringFutureValueCents(
        1200,
        BillingPeriod.monthly,
        years: 10,
        annualRate: 0,
      ),
      144000,
    );
  });
}

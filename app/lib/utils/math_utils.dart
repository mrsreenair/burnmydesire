import 'dart:math' as math;

/// Benchmark annual return used for opportunity-cost projections.
/// Historical S&P 500 average; user-adjustable in Pro (v1.x).
const double kDefaultAnnualRate = 0.08;

/// Projection horizons offered in the shock card, in years.
const List<int> kHorizons = [10, 20, 30];

/// Default horizon highlighted in the shock card.
const int kDefaultHorizonYears = 20;

/// Future value of [principalCents] invested at [annualRate] for [years],
/// compounded annually: A = P(1 + r)^t. All money is integer cents.
int futureValueCents(
  int principalCents, {
  double annualRate = kDefaultAnnualRate,
  required int years,
}) {
  assert(principalCents >= 0 && years >= 0);
  return (principalCents * math.pow(1 + annualRate, years)).round();
}

/// What the purchase "steals" from the buyer's future: future value minus
/// the price itself (they'd still have spent the principal either way).
int foregoneGrowthCents(
  int principalCents, {
  double annualRate = kDefaultAnnualRate,
  required int years,
}) =>
    futureValueCents(principalCents, annualRate: annualRate, years: years) -
    principalCents;

/// How often a recurring cost is charged.
enum BillingPeriod { weekly, monthly, yearly }

/// Charges per year, for turning any billing period into a common unit.
int chargesPerYear(BillingPeriod period) => switch (period) {
  BillingPeriod.weekly => 52,
  BillingPeriod.monthly => 12,
  BillingPeriod.yearly => 1,
};

/// A year of a recurring cost — the honest unit for a subscription.
///
/// Counting a cancelled subscription's whole lifetime as "protected"
/// would let one tap add thousands to the total, which is exactly the
/// kind of number that makes the rest of them worthless. A year is real,
/// bounded, and still far bigger than people expect.
int yearlyCostCents(int amountCents, BillingPeriod period) =>
    amountCents * chargesPerYear(period);

/// What a recurring cost becomes if the money is invested instead of
/// spent — the future value of a stream of payments, not a lump sum.
///
/// This is the whole point of subscription mode. €12 a month looks like
/// nothing next to a €400 gadget, but paid monthly into a market
/// returning 8% it is worth roughly €18,000 after twenty years, because
/// every payment compounds from the moment it would have been made.
/// Treating it as a single lump sum understates it by a factor of ten.
///
/// Contributions are made at the end of each period (an ordinary
/// annuity), the conservative choice: assuming payment at the start
/// would inflate the result by one period's growth.
int recurringFutureValueCents(
  int amountCents,
  BillingPeriod period, {
  double annualRate = kDefaultAnnualRate,
  required int years,
}) {
  assert(amountCents >= 0 && years >= 0);
  final n = chargesPerYear(period);
  final periods = n * years;
  if (periods == 0) return 0;
  final ratePerPeriod = math.pow(1 + annualRate, 1 / n) - 1.0;
  // The zero-rate case would divide by zero; it's also just the total.
  if (ratePerPeriod <= 0) return amountCents * periods;
  final growth = math.pow(1 + ratePerPeriod, periods) - 1;
  return (amountCents * growth / ratePerPeriod).round();
}

/// Everything the recurring cost will simply take, ignoring growth.
int recurringTotalPaidCents(
  int amountCents,
  BillingPeriod period, {
  required int years,
}) => amountCents * chargesPerYear(period) * years;

/// An installment ("buy now pay later") plan for a purchase.
class InstallmentPlan {
  const InstallmentPlan({required this.monthlyCents, required this.months});

  final int monthlyCents;
  final int months;

  int get totalPaidCents => monthlyCents * months;

  /// How much more than the sticker price the plan costs.
  int overpaymentCents(int priceCents) => totalPaidCents - priceCents;

  /// The full damage: everything paid plus the growth the price would have
  /// earned if invested instead.
  int trueCostCents(
    int priceCents, {
    required int years,
    double annualRate = kDefaultAnnualRate,
  }) =>
      totalPaidCents +
      foregoneGrowthCents(priceCents, annualRate: annualRate, years: years);
}

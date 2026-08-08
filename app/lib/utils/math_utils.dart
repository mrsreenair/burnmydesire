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
  int trueCostCents(int priceCents, {required int years}) =>
      totalPaidCents + foregoneGrowthCents(priceCents, years: years);
}

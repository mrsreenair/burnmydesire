/// Turning store products into the numbers a paywall actually shows.
///
/// Kept free of RevenueCat types on purpose: the arithmetic here decides
/// what people are told they'll be charged, so it has to be testable
/// without a store, a network, or a device.
library;

/// How a plan recurs. Lifetime is a one-off purchase, not a subscription.
enum PlanPeriod { weekly, monthly, annual, lifetime, other }

/// Parses an ISO 8601 subscription period ("P1M", "P1Y", "P1W") into the
/// shape the paywall reasons about. Anything unexpected is [other] rather
/// than a guess — a mislabelled plan is worse than an unlabelled one.
PlanPeriod planPeriodFrom(String? iso) {
  switch (iso) {
    case 'P1W':
    case 'P7D':
      return PlanPeriod.weekly;
    case 'P1M':
      return PlanPeriod.monthly;
    case 'P1Y':
    case 'P12M':
      return PlanPeriod.annual;
    case null:
      return PlanPeriod.lifetime;
    default:
      return PlanPeriod.other;
  }
}

/// Whole days of free trial in an ISO 8601 intro period, or null when the
/// plan has no trial. Months are 30 days and years 365 — close enough for
/// "7 days free", and the exact wording always comes from the store.
int? trialDaysFrom(String? iso) {
  if (iso == null || iso.length < 3 || !iso.startsWith('P')) return null;
  final unit = iso[iso.length - 1];
  final count = int.tryParse(iso.substring(1, iso.length - 1));
  if (count == null || count <= 0) return null;
  return switch (unit) {
    'D' => count,
    'W' => count * 7,
    'M' => count * 30,
    'Y' => count * 365,
    _ => null,
  };
}

/// What the annual plan saves against paying monthly for a year, as whole
/// percent. Null when there's nothing to compare, when the maths would be
/// meaningless, or when annual isn't actually cheaper — a "Save -4%" badge
/// is the kind of thing that gets an app called a scam.
int? annualSavingsPercent({
  required double monthlyPrice,
  required double annualPrice,
}) {
  if (monthlyPrice <= 0 || annualPrice <= 0) return null;
  final yearOfMonthly = monthlyPrice * 12;
  if (annualPrice >= yearOfMonthly) return null;
  final percent = ((1 - annualPrice / yearOfMonthly) * 100).round();
  return percent <= 0 ? null : percent;
}

/// The per-month equivalent of an annual price, for the "€1.67/mo" line
/// every subscription app shows under a yearly plan.
double perMonthFromAnnual(double annualPrice) => annualPrice / 12;
